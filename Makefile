DIST_DIR = ./dist
PUBLIC_DIR = $(DIST_DIR)/public
DIST_VIEWS_DIR = $(DIST_DIR)/views
DIST_LIB_DIR = $(DIST_DIR)/lib
DIST_CSS_DIR = $(PUBLIC_DIR)/css
DIST_IMG_DIR = $(PUBLIC_DIR)/img
DIST_JS_DIR = $(PUBLIC_DIR)/js
DIST_FONT_DIR = $(PUBLIC_DIR)/font

JS_SRC_DIR = ./js
LESS_SRC_DIR = ./less
IMG_SRC_DIR = ./img
FONT_SRC_DIR = ./font
APP_SRC_DIR = ./app

CHECK=\033[32m✔\033[39m
HR=\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#

dist: build-js build-css build-font build-img build-app


# CLEANS THE ROOT DIRECTORY OF PRIOR BUILDS
clean:
	-rm -r $(DIST_DIR)

# run the application
run:
	@ruby $(DIST_DIR)/app.rb

# JS COMPILE
build-js: $(JS_SRC_DIR)/*.js
	@echo "\n${HR}"
	@echo "Building Javascript..."
	@mkdir -p $(DIST_JS_DIR)
	@cat $(JS_SRC_DIR)/jquery-1.9.1.js $(JS_SRC_DIR)/bootstrap-dropdown.js $(JS_SRC_DIR)/bootstrap-tooltip.js $(JS_SRC_DIR)/bootstrap-popover.js $(JS_SRC_DIR)/bootstrap-modal.js $(JS_SRC_DIR)/jquery.tagsinput.min.js $(JS_SRC_DIR)/bootstrapSwitch.js $(JS_SRC_DIR)/application.js > $(DIST_JS_DIR)/app.js 
	@uglifyjs -nc $(DIST_JS_DIR)/app.js > $(DIST_JS_DIR)/app.min.js
	@rm $(DIST_JS_DIR)/app.js
	@echo "                                            ${CHECK} Done"
	@echo "${HR}\n"

# CSS COMPILE
build-css: $(LESS_SRC_DIR)/bootstrap.less
	@echo "\n${HR}"
	@echo "Building CSS..."
	@mkdir -p $(DIST_CSS_DIR)
	@recess --compress $(LESS_SRC_DIR)/bootstrap.less > $(DIST_CSS_DIR)/app.css
	@echo "                                            ${CHECK} Done"
	@echo "${HR}\n"

# IMAGES
build-img: $(IMG_SRC_DIR)/*
	@echo "\n${HR}"
	@echo "Building Images..."
	@mkdir -p $(DIST_IMG_DIR)
	@cp $(IMG_SRC_DIR)/* $(DIST_IMG_DIR)
	@echo "                                            ${CHECK} Done"
	@echo "${HR}\n"

# FONT
build-font: $(FONT_SRC_DIR)/*
	@echo "\n${HR}"
	@echo "Building Fonts..."
	@mkdir -p $(DIST_FONT_DIR)
	@cp $(FONT_SRC_DIR)/* $(DIST_FONT_DIR)
	@echo "                                            ${CHECK} Done"
	@echo "${HR}\n"

# FONT
build-app: $(APP_SRC_DIR)/*
	@echo "\n${HR}"
	@echo "Building App..."
	@mkdir -p $(DIST_VIEWS_DIR)
	@cp -r $(APP_SRC_DIR)/views/* $(DIST_VIEWS_DIR)
	@mkdir -p $(DIST_LIB_DIR)
	@cp $(APP_SRC_DIR)/lib/*.rb $(DIST_LIB_DIR)
	@cp $(APP_SRC_DIR)/*.rb $(DIST_DIR)
	@echo "                                            ${CHECK} Done"
	@echo "${HR}\n"

.PHONY: dist build-img build-css build-js build-font