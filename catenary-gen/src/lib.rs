use rgb::AsPixels;

const WHITE: rgb::RGBA8 = rgb::RGBA8::new(u8::MAX, u8::MAX, u8::MAX, u8::MAX);

#[derive(Clone, Copy)]
pub struct CenteredCatenary {
    /// a is the minima of the curve, at (0, a)
    pub a: f64,
}

impl CenteredCatenary {
    /// arc length will be set to the minimum if it is too short
    pub fn new_from_params(dist_h: f64, dist_v: f64, mut arc_length: f64) -> anyhow::Result<Self> {
        struct SimpleFunc<F: Fn(f64) -> f64> {
            f: F,
        }

        impl<F: Fn(f64) -> f64> argmin::core::CostFunction for SimpleFunc<F> {
            type Param = f64;
            type Output = f64;

            fn cost(&self, param: &Self::Param) -> Result<Self::Output, anyhow::Error> {
                Ok((self.f)(*param))
            }
        }

        let min_arc = (dist_h * dist_h + dist_v * dist_v).sqrt();
        if arc_length < min_arc {
            arc_length = min_arc + 1e-5
        }

        let func_a = SimpleFunc {
            f: |a: f64| {
                // from https://en.wikipedia.org/wiki/Catenary#Determining_parameters
                let l_eq = f64::sqrt(arc_length * arc_length - dist_v * dist_v);
                let r_eq = (2.0 * a) * f64::sinh(dist_h / (2.0 * a));
                l_eq - r_eq
            },
        };

        //dbg!(func_a(5.0), func_a(10.0), func_a(20.0), func_a(50.0));

        let solver = argmin::solver::brent::BrentRoot::new(0.0, 1e10, 1e-15);

        let res = argmin::core::Executor::new(func_a, solver)
            .configure(|state| state.max_iters(1000).param(20.0))
            .run()?;

        let a = res.state().best_param.unwrap();

        Ok(CenteredCatenary { a })
    }

    /// returns the y value at x
    pub fn evaluate_at_x(&self, x: f64) -> f64 {
        self.a * f64::cosh(x / self.a)
    }

    /// returns the positive x value at y
    pub fn evaluate_at_y(&self, y: f64) -> f64 {
        self.a * f64::acosh(y / self.a)
    }

    pub fn find_point_pair(&self, dist_h: f64, dist_v: f64) -> anyhow::Result<f64> {
        // maths derived from:
        //      y_dif = self.evaluate_at_x(x0 + dist_x) - self.evaluate_at_x(x0);
        // using cosh x - cosh y = 2 sinh[ (x+y)/2 ] sinh[ (x-y)/2 ]

        let h_2 = dist_h / 2.0;
        let v = dist_v;

        let sh = f64::sinh(h_2 / self.a);
        let r = v / (2.0 * self.a * sh);
        let x0 = f64::asinh(r) * self.a - h_2;

        let y_dif = self.evaluate_at_x(x0 + dist_h) - self.evaluate_at_x(x0);
        let dif = (y_dif - dist_v).abs();
        if dif > 1e-5 {
            dbg!(y_dif, dist_v);
            anyhow::bail!("dif too big: {}", dif);
        }

        Ok(x0)
    }
}

pub struct Catenary {
    pub cat: CenteredCatenary,
    pub disp_x: f64,
    pub disp_y: f64,
    pub bounds: (usize, usize),
}

impl Catenary {
    pub fn render_catenary_x(&self, buf: &mut [rgb::RGBA8], w: usize, h: usize) {
        for col in 0..w {
            let x = col as f64 + self.disp_x;
            let y = self.cat.evaluate_at_x(x);

            let y_row_inv = (y - self.disp_y).round();

            let row = h as f64 - 1.0 - y_row_inv;
            if row < 0.0 || (row as usize) >= h {
                continue;
            }
            let row = row as usize;

            let i = row * w + col;
            buf[i] = WHITE;
        }
    }

    pub fn render_catenary_y(&self, buf: &mut [rgb::RGBA8], w: usize, h: usize) {
        for row in 0..h {
            let y = (h - 1 - row) as f64 + self.disp_y;
            let x = self.cat.evaluate_at_y(y);
            let col1 = x - self.disp_x;
            let col2 = -x - self.disp_x;
            for col in [col1.round(), col2.round()] {
                if col >= 0.0 && (col as usize) < w {
                    let col = col as usize;
                    let i = row * w + col;
                    buf[i] = WHITE;
                }
            }
        }
    }

    pub fn render_catenary(&self, buf: &mut [rgb::RGBA8], w: usize, h: usize) {
        self.render_catenary_x(buf, w, h);
        self.render_catenary_y(buf, w, h);
    }

    /// arc length will be set to the minimum if it is too short
    pub fn new(dist_h: f64, dist_v: f64, arc_length: f64) -> anyhow::Result<Self> {
        let cat = CenteredCatenary::new_from_params(dist_h, dist_v, arc_length)?;
        // a is the minima of the curve, at (0, a)
        dbg!(cat.a);

        // x0 is the point on the left
        let x0 = cat.find_point_pair(dist_h, dist_v)?;
        dbg!(x0);

        // disp_x will shift so the minima is at (-zero_x, a) and p0 is at (0,0)
        let disp_x = x0;

        let y0 = cat.evaluate_at_x(x0);
        let y1 = cat.evaluate_at_x(x0 + dist_h);
        let point_y_min = y0.min(y1);

        let disp_y = if x0.signum() != (x0 + dist_h).signum() {
            // x0 is on one side of the y axis, x1 on the other

            // minima is visible
            // this will shift the minima so that it is at (-zero_x, 0)
            cat.a
        } else {
            // minima not visible, min is at one of the extremities
            point_y_min
        };

        // extra vertical space needed is the amount of "drooping"
        // caused by the minima. it is only non-zero if the minima is visible
        let extra_v = point_y_min - disp_y;

        let w = dist_h;
        let h = f64::abs(dist_v) + extra_v;
        let bounds = (w.ceil() as usize, h.ceil() as usize);

        Ok(Self {
            cat,
            disp_x,
            disp_y,
            bounds,
        })
    }

    pub fn render_new_tex(&self) -> Vec<u8> {
        let (w, h) = self.bounds;
        let mut buf = vec![0_u8; w * h * 4];
        let pixels: &mut [rgb::RGBA8] = buf.as_mut_slice().as_pixels_mut();
        self.render_catenary(pixels, w, h);
        buf
    }
}

#[cfg(test)]
mod test {
    use crate::Catenary;
    const BLANK: rgb::RGBA8 = rgb::RGBA8::new(0, 0, 0, 0);

    #[test]
    fn test() {
        let dist_v = 1000.0;
        let dist_h = 1500.0;
        let arc_len = 2500.0;
        let cat = Catenary::new(dist_h, dist_v, arc_len).unwrap();
        let (w, h) = cat.bounds;

        let mut buf = vec![BLANK; w * h];
        cat.render_catenary(&mut buf, w, h);
        lodepng::encode32_file("generated_images/cat.png", &buf, w, h).unwrap();

        let mut buf = vec![BLANK; w * h];
        cat.render_catenary_x(&mut buf, w, h);
        lodepng::encode32_file("generated_images/cat_x.png", &buf, w, h).unwrap();

        let mut buf = vec![BLANK; w * h];
        cat.render_catenary_y(&mut buf, w, h);
        lodepng::encode32_file("generated_images/cat_y.png", &buf, w, h).unwrap();
    }
}
