#!/usr/bin/env ruby
# Adds the NepaliDateWidgetExtension target to the Xcode project.
# Run from the ios/ directory:  ruby add_widget_extension.rb
#
# Requires the xcodeproj gem (ships with CocoaPods):
#   gem install xcodeproj   (or just use the one bundled with CocoaPods)

require 'xcodeproj'

PROJECT_PATH       = File.expand_path('Runner.xcodeproj', __dir__)
WIDGET_DIR_NAME    = 'NepaliDateWidget'
WIDGET_TARGET_NAME = 'NepaliDateWidgetExtension'
APP_GROUP          = 'group.com.babaal.patro'
TEAM_ID            = 'MS9L6Q7DYC'
BUNDLE_ID_BASE     = 'com.babaal.patro'
WIDGET_BUNDLE_ID   = "#{BUNDLE_ID_BASE}.NepaliDateWidgetExtension"
DEPLOYMENT_TARGET  = '14.0'

project = Xcodeproj::Project.open(PROJECT_PATH)

# ── Guard: don't add twice ──────────────────────────────────────────────────
if project.targets.any? { |t| t.name == WIDGET_TARGET_NAME }
  puts "✅  '#{WIDGET_TARGET_NAME}' target already exists — nothing to do."
  exit 0
end

runner_target = project.targets.find { |t| t.name == 'Runner' }
abort("❌  Could not find 'Runner' target") unless runner_target

# ── 1. Create the widget extension target ──────────────────────────────────
widget_target = project.new_target(
  :app_extension,
  WIDGET_TARGET_NAME,
  :ios,
  DEPLOYMENT_TARGET
)

# ── 2. Create a PBXGroup for the widget source files ──────────────────────
widget_group = project.main_group.new_group(WIDGET_DIR_NAME, WIDGET_DIR_NAME)

# ── 3. Add file references ─────────────────────────────────────────────────
def add_file(group, filename, type)
  ref = group.new_file(filename)
  ref.last_known_file_type = type
  ref
end

swift_files = [
  add_file(widget_group, 'NepaliDateWidget.swift',       'sourcecode.swift'),
  add_file(widget_group, 'NepaliDateWidgetBundle.swift', 'sourcecode.swift'),
]
assets_ref      = add_file(widget_group, 'Assets.xcassets',               'folder.assetcatalog')
plist_ref       = add_file(widget_group, 'Info.plist',                    'text.plist.xml')
entitlements_ref = add_file(widget_group, 'NepaliDateWidget.entitlements', 'text.plist.entitlements')

# ── 4. Add source files to Sources build phase ────────────────────────────
swift_files.each { |ref| widget_target.source_build_phase.add_file_reference(ref) }

# ── 5. Add assets to Resources build phase ────────────────────────────────
widget_target.resources_build_phase.add_file_reference(assets_ref)

# ── 6. Configure build settings for all configurations ───────────────────
widget_target.build_configurations.each do |cfg|
  s = cfg.build_settings
  s['SWIFT_VERSION']                           = '5.0'
  s['PRODUCT_BUNDLE_IDENTIFIER']               = WIDGET_BUNDLE_ID
  s['INFOPLIST_FILE']                          = "#{WIDGET_DIR_NAME}/Info.plist"
  s['CODE_SIGN_STYLE']                         = 'Automatic'
  s['DEVELOPMENT_TEAM']                        = TEAM_ID
  s['SKIP_INSTALL']                            = 'YES'
  s['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES']   = 'NO'
  s['TARGETED_DEVICE_FAMILY']                  = '1,2'
  s['IPHONEOS_DEPLOYMENT_TARGET']              = DEPLOYMENT_TARGET
  s['CODE_SIGN_ENTITLEMENTS']                  = "#{WIDGET_DIR_NAME}/NepaliDateWidget.entitlements"
  s['LD_RUNPATH_SEARCH_PATHS']                 = [
    '$(inherited)',
    '@executable_path/../../Frameworks',
    '@executable_path/Frameworks'
  ]
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'

  case cfg.name
  when 'Debug'
    s['SWIFT_OPTIMIZATION_LEVEL']          = '-Onone'
    s['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG'
    s['DEBUG_INFORMATION_FORMAT']          = 'dwarf'
  when 'Release', 'Profile'
    s['SWIFT_OPTIMIZATION_LEVEL']  = '-O'
    s['SWIFT_COMPILATION_MODE']    = 'wholemodule'
    s['DEBUG_INFORMATION_FORMAT']  = 'dwarf-with-dsym'
    s['VALIDATE_PRODUCT']          = 'YES'
  end
end

# ── 7. Add entitlements to Runner (App Group) ─────────────────────────────
runner_target.build_configurations.each do |cfg|
  cfg.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# ── 8. Create "Embed App Extensions" copy-files phase in Runner ───────────
embed_phase = runner_target.build_phases.find do |p|
  p.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) &&
    p.name == 'Embed App Extensions'
end

unless embed_phase
  embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed_phase.name               = 'Embed App Extensions'
  embed_phase.dst_subfolder_spec = '13'  # PlugIns / App Extensions
  embed_phase.dst_path           = ''
  runner_target.build_phases << embed_phase
end

# ── 9. Add widget.appex product to that embed phase ───────────────────────
widget_product = widget_target.product_reference
embed_build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
embed_build_file.file_ref = widget_product
embed_build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
embed_phase.files << embed_build_file

# ── 10. Add widget.appex to Products group ────────────────────────────────
products_group = project.main_group.recursive_children_groups.find { |g| g.name == 'Products' }
if products_group && !products_group.children.include?(widget_product)
  products_group.children << widget_product
end

# ── 11. Add target dependency: Runner depends on widget extension ─────────
proxy = project.new(Xcodeproj::Project::Object::PBXContainerItemProxy)
proxy.container_portal        = project.root_object.uuid
proxy.proxy_type              = '1'
proxy.remote_global_id_string = widget_target.uuid
proxy.remote_info             = WIDGET_TARGET_NAME

dep = project.new(Xcodeproj::Project::Object::PBXTargetDependency)
dep.target       = widget_target
dep.target_proxy = proxy
runner_target.dependencies << dep

# ── Save ──────────────────────────────────────────────────────────────────
project.save
puts "✅  '#{WIDGET_TARGET_NAME}' target added successfully!"
puts "    Next steps:"
puts "    1. Open ios/ in Xcode and verify the new target appears."
puts "    2. Enable App Groups capability for both Runner and #{WIDGET_TARGET_NAME}"
puts "       (Signing & Capabilities → + → App Groups → #{APP_GROUP})"
puts "    3. Run: cd ios && pod install"
puts "    4. Build & run from Xcode."
