use catenary_gen::Catenary;

pub struct TemplateApp {
    x_dist: f64,
    y_dist: f64,
    arc_len: f64,
    texture_bytes: Vec<u8>,
    texture: egui::TextureHandle,
    scale: usize,
}

impl TemplateApp {
    /// Called once before the first frame.
    pub fn new(cc: &eframe::CreationContext<'_>) -> Self {
        //egui_extras::install_image_loaders(&cc.egui_ctx);

        cc.egui_ctx
            .style_mut(|style| style.spacing.slider_width = 1000.0);

        let x_dist = 100.0;
        let y_dist = 100.0;
        let arc_len = 250.0;

        let cat = Catenary::new(x_dist, y_dist, arc_len).unwrap();

        let texture_bytes = cat.render_new_tex();
        let (w, h) = cat.bounds;

        let im = egui::ColorImage::from_rgba_unmultiplied([w, h], &texture_bytes);

        let texture = cc
            .egui_ctx
            .load_texture("texture", im, egui::TextureOptions::NEAREST);

        Self {
            x_dist,
            y_dist,
            arc_len,
            texture,
            scale: 3,
            texture_bytes,
        }
    }

    pub fn update_texture(&mut self, egui_ctx: &egui::Context) {
        let cat = Catenary::new(self.x_dist, self.y_dist, self.arc_len).unwrap();

        let texture_bytes = cat.render_new_tex();
        let (w, h) = cat.bounds;

        let im = egui::ColorImage::from_rgba_unmultiplied([w, h], &texture_bytes);

        let texture = egui_ctx.load_texture("texture", im, egui::TextureOptions::NEAREST);
        self.texture = texture;
        self.texture_bytes = texture_bytes;
    }
}

impl eframe::App for TemplateApp {
    /// Called by the frame work to save state before shutdown.
    fn save(&mut self, _storage: &mut dyn eframe::Storage) {}

    /// Called each time the UI needs repainting, which may be many times per second.
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        // Put your widgets into a `SidePanel`, `TopBottomPanel`, `CentralPanel`, `Window` or `Area`.
        // For inspiration and more examples, go to https://emilk.github.io/egui

        egui::TopBottomPanel::top("top_panel").show(ctx, |ui| {
            // The top panel is often a good place for a menu bar:

            egui::menu::bar(ui, |ui| {
                // NOTE: no File->Quit on web pages!
                let is_web = cfg!(target_arch = "wasm32");
                if !is_web {
                    ui.menu_button("File", |ui| {
                        if ui.button("Quit").clicked() {
                            ctx.send_viewport_cmd(egui::ViewportCommand::Close);
                        }
                    });
                    ui.add_space(16.0);
                }

                egui::widgets::global_dark_light_mode_buttons(ui);
            });
        });

        egui::CentralPanel::default().show(ctx, |ui| {
            let mut changed = false;

            changed |= ui
                .add(
                    egui::Slider::new(&mut self.x_dist, 0.0..=2048.0)
                        .text("x distance between points")
                        .clamp_to_range(false),
                )
                .changed();

            changed |= ui
                .add(
                    egui::Slider::new(&mut self.y_dist, -2048.0..=2048.0)
                        .text("y distance between points")
                        .clamp_to_range(false),
                )
                .changed();

            changed |= ui
                .add(egui::Slider::new(&mut self.arc_len, 0.0..=5000.0).text("arc length"))
                .changed();

            if changed {
                self.update_texture(ctx);
            }

            ui.separator();

            ui.add(
                egui::Slider::new(&mut self.scale, 1..=10)
                    .text("scale")
                    .integer(),
            );

            if ui.button("save").clicked() {
                let [w, h] = self.texture.size();
                catenary_gen::lodepng::encode32_file("image.png", &self.texture_bytes, w, h)
                    .unwrap();
            }
            egui::ScrollArea::both().show(ui, |ui| {
                let im = egui::Image::new((
                    self.texture.id(),
                    self.texture.size_vec2() * self.scale as f32,
                ));

                ui.add(im);
            });

            ui.with_layout(egui::Layout::bottom_up(egui::Align::LEFT), |ui| {
                powered_by_egui_and_eframe(ui);
                egui::warn_if_debug_build(ui);
            });
        });
    }
}

fn powered_by_egui_and_eframe(ui: &mut egui::Ui) {
    ui.horizontal(|ui| {
        ui.spacing_mut().item_spacing.x = 0.0;
        ui.label("Powered by ");
        ui.hyperlink_to("egui", "https://github.com/emilk/egui");
        ui.label(" and ");
        ui.hyperlink_to(
            "eframe",
            "https://github.com/emilk/egui/tree/master/crates/eframe",
        );
        ui.label(".");
    });
}
