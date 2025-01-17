use rgb::AsPixels;

const WHITE: rgb::RGBA8 = rgb::RGBA8::new(u8::MAX, u8::MAX, u8::MAX, u8::MAX);

#[derive(Clone, Copy, Debug)]
pub struct CenteredCatenary {
    /// a is the minima of the curve, at (0, a)
    pub a: f64,
}

impl CenteredCatenary {
    #[allow(non_snake_case)]
    pub fn new_from_params(dist_h: f64, dist_v: f64, slack: f64) -> anyhow::Result<Self> {
        let min_arc = (dist_h * dist_h + dist_v * dist_v).sqrt();
        let arc_length = min_arc + slack.max(1e-3);

        let sqrt = f64::sqrt;
        let sinh = f64::sinh;
        let cosh = f64::cosh;

        let h = dist_h;
        let v = dist_v;
        let L = arc_length;

        // TODO: could use https://crates.io/crates/astro-float for better precision
        // would need to implement roots::FloatType on it

        // Inaccurate for small a, will return very big numbers or Inf
        let func_a = |a: f64| {
            let a2 = a * 2.0;
            a2 * sinh(h / a2) - sqrt(L * L - v * v)
        };

        // This is inaccurate for small a, could return 0, Inf, Nan, -Inf
        let func_a_deriv = |a: f64| {
            let a2 = a * 2.0;
            let left = 2.0 * sinh(h / a2);
            let right = h / a * cosh(h / a2);
            left - right
        };

        let mut conv = roots::SimpleConvergency {
            eps: 1e-10,
            max_iter: 1e4 as usize,
        };

        let res = roots::find_root_newton_raphson(20.0, func_a, func_a_deriv, &mut conv);
        let a = match res {
            Ok(a) => a.abs(),
            Err(_e) => {
                //dbg!(e);
                // derivate for small a is inacurrate since it substracts huge numbers
                // try brent?
                roots::find_root_brent(1.0, 20.0, func_a, &mut conv)?
            }
        };

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

        let l = self.a * f64::sinh((x0 + dist_h) / self.a) - self.a * f64::sinh((x0) / self.a);
        dbg!(l);

        Ok(x0)
    }
}

#[derive(Debug)]
pub struct Catenary {
    pub cat: CenteredCatenary,
    pub disp_x: f64,
    pub disp_y: f64,
    pub bounds: (usize, usize),
}

impl Catenary {
    pub fn render_catenary_x(&self, mut draw: impl FnMut(usize, usize)) {
        let (w, h) = self.bounds;
        for col in 0..w {
            let x = col as f64 + self.disp_x;
            let y = self.cat.evaluate_at_x(x);

            let y_row_inv = (y - self.disp_y).round();

            let row = h as f64 - 1.0 - y_row_inv;
            if row < 0.0 || (row as usize) >= h {
                continue;
            }
            draw(col, row as usize);
        }
    }

    pub fn render_catenary_y(&self, mut draw: impl FnMut(usize, usize)) {
        let max_y_at_0 = self.cat.evaluate_at_x(0 as f64 + self.disp_x);

        let (w, h) = self.bounds;
        for row in 0..h {
            let y = (h - 1 - row) as f64 + self.disp_y;
            let x = self.cat.evaluate_at_y(y);
            let col1 = x - self.disp_x;
            let col2 = -x - self.disp_x;
            for col in [col1.round(), col2.round()] {
                if col > 0.0 && (col as usize) < w || col == 0.0 && y <= max_y_at_0 {
                    draw(col as usize, row);
                }
            }
        }
    }

    pub fn render_catenary(&self, mut draw: impl FnMut(usize, usize)) {
        self.render_catenary_x(&mut draw);
        self.render_catenary_y(draw);
    }

    /// arc length will be set to the minimum if it is too short
    pub fn new(dist_h: f64, dist_v: f64, slack: f64) -> anyhow::Result<Self> {
        let cat = CenteredCatenary::new_from_params(dist_h, dist_v, slack)?;
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

        // not sure why this +2.0 is needed but it gets rid of pixels not appearing
        let w = dist_h + 2.0;
        let h = f64::abs(dist_v) + extra_v.round();
        let bounds = (w as usize, h as usize);

        Ok(Self {
            cat,
            disp_x,
            disp_y,
            bounds,
        })
    }

    pub fn render_new_tex(&self, flipped_x: bool) -> Vec<u8> {
        let (w, h) = self.bounds;
        let mut buf = vec![0_u8; w * h * 4];
        let pixels: &mut [rgb::RGBA8] = buf.as_mut_slice().as_pixels_mut();
        self.render_catenary(|mut x, y| {
            if flipped_x {
                x = w - 1 - x;
            }
            let i = y * w + x;
            pixels[i] = WHITE;
        });
        buf
    }
}

#[cfg(test)]
mod test {
    use crate::{Catenary, WHITE};
    const BLANK: rgb::RGBA8 = rgb::RGBA8::new(0, 0, 0, 0);

    #[test]
    fn test() {
        let dist_v = 100.0;
        let dist_h = 100.0;
        let arc_len = 250.0;
        let cat = Catenary::new(dist_h, dist_v, arc_len).unwrap();
        let (w, h) = cat.bounds;

        let mut buf = vec![BLANK; w * h];
        cat.render_catenary(|x, y| {
            let i = y * w + x;
            buf[i] = WHITE;
        });
        lodepng::encode32_file("generated_images/cat.png", &buf, w, h).unwrap();

        let mut buf = vec![BLANK; w * h];
        cat.render_catenary_x(|x, y| {
            let i = y * w + x;
            buf[i] = WHITE;
        });
        lodepng::encode32_file("generated_images/cat_x.png", &buf, w, h).unwrap();

        let mut buf = vec![BLANK; w * h];
        cat.render_catenary_y(|x, y| {
            let i = y * w + x;
            buf[i] = WHITE;
        });
        lodepng::encode32_file("generated_images/cat_y.png", &buf, w, h).unwrap();
    }
}
