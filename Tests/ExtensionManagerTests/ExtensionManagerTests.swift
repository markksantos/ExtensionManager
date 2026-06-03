import XCTest
@testable import ExtensionManager

final class ExtensionCategoryTests: XCTestCase {
     func test_all_categories_have_icons() {
           for category in ExtensionCategory.allCases {
               XCTAssertFalse(category.iconName.isEmpty,
                    "\(category.rawValue) has no icon name")
           }
      }

     func test_all_categories_have_descriptions() {
          for category in ExtensionCategory.allCases {
               XCTAssertFalse(category.description.isEmpty,
                    "\(category.rawValue) has no description")
           }
      }

     func test_from_sdk_finder_sync() {
          XCTAssertEqual(ExtensionCategory.from(sdk: "com.apple.findersync"), .finderSync)
      }

     func test_from_sdk_share_services() {
          let a = ExtensionCategory.from(sdk: "com.apple.share-services")
          XCTAssertEqual(a, .shareServices)
          let b = ExtensionCategory.from(sdk: "com.apple.share.Facebook")
          XCTAssertEqual(b, .shareServices)
      }

     func test_from_sdk_quicklook() {
          XCTAssertEqual(ExtensionCategory.from(sdk: "com.apple.quicklook.preview"), .quickLookPreview)
          XCTAssertEqual(ExtensionCategory.from(sdk: "com.apple.quicklook.thumbnail"), .quickLookThumbnail)
      }

     func test_from_sdk_widgetkit() {
          XCTAssertEqual(ExtensionCategory.from(sdk: "com.apple.widgetkit"), .widgetKit)
      }

     func test_from_sdk_safari() {
          let a = ExtensionCategory.from(sdk: "com.apple.Safari.web-extension")
          XCTAssertEqual(a, .safariWebExtension)
          let b = ExtensionCategory.from(sdk: "com.apple.safari")
          XCTAssertEqual(b, .safariWebExtension)
      }

     func test_from_sdk_network_extension() {
          XCTAssertEqual(ExtensionCategory.from(sdk: "com.apple.network_extension"), .networkExtension)
          XCTAssertEqual(ExtensionCategory.from(sdk: "com.apple.networkextension"), .networkExtension)
      }

     func test_from_sdk_driverkit() {
          let a = ExtensionCategory.from(sdk: "com.apple.driver_extension")
          XCTAssertEqual(a, .driverExtension)
          let b = ExtensionCategory.from(sdk: "DriverKit.DriverKit")
          XCTAssertEqual(b, .driverExtension)
      }

     func test_from_sdk_credential() {
          XCTAssertEqual(ExtensionCategory.from(sdk: "com.apple.credential"), .credentialProvider)
      }

     func test_from_sdk_content_filter() {
          XCTAssertEqual(ExtensionCategory.from(sdk: "com.apple.content-filter"), .contentFilter)
      }

     func test_from_sdk_unknown_returns_other() {
          XCTAssertEqual(ExtensionCategory.from(sdk: "com.apple.unknown.custom"), .other)
      }

     func test_from_system_extension_network() {
          XCTAssertEqual(ExtensionCategory.fromSystemExtension(type: "NetworkExtension"), .networkExtension)
      }

     func test_from_system_extension_driver() {
          XCTAssertEqual(ExtensionCategory.fromSystemExtension(type: "DriverExtension"), .driverExtension)
      }

     func test_from_system_extension_unknown_returns_other() {
          XCTAssertEqual(ExtensionCategory.fromSystemExtension(type: "UnknownType"), .other)
      }
}

final class SystemExtensionTests: XCTestCase {
     func test_isUserInstalled_applications() {
          let ext = SystemExtension.make(path: "/Applications/Slack.app/Contents/PlugIn/slack.fs")
          XCTAssertTrue(ext.isUserInstalled)
      }

     func test_isUserInstalled_users_dir() {
          let ext = SystemExtension.make(path: "/Users/mark/Library/Application Support/MyExt.appex")
          XCTAssertTrue(ext.isUserInstalled)
      }

     func test_isUserInstalled_system_not_installed() {
          let ext = SystemExtension.make(path: "/System/Library/AppleFS/FileProvider.fs")
          XCTAssertFalse(ext.isUserInstalled)
      }

     func test_appName_prefers_parent_name() {
          let ext = SystemExtension.make(displayName: "", parentName: "Slack")
          XCTAssertEqual(ext.appName, "Slack")
      }

     func test_appName_falls_back_to_display_name() {
          let ext = SystemExtension.make(displayName: "Dropbox File Provider", parentName: "")
          XCTAssertEqual(ext.appName, "Dropbox File Provider")
      }

     func test_appName_computes_from_bundle_id() {
          // With 4+ components, uses the second-to-last component, capitalized.
          let ext = SystemExtension.make(bundleIdentifier: "com.google.drivefs.Provider",
                                         displayName: "", parentName: "")
          XCTAssertEqual(ext.appName, "Drivefs")
          let ext2 = SystemExtension.make(bundleIdentifier: "com.example.myapp.Helper",
                                          displayName: "", parentName: "")
          XCTAssertEqual(ext2.appName, "Myapp")
      }

     func test_appName_three_component_bundle_id() {
          // For a 3-component ID, second-to-last is the vendor token.
          let ext = SystemExtension.make(bundleIdentifier: "com.dropbox.fileprovider",
                                         displayName: "", parentName: "")
          XCTAssertEqual(ext.appName, "Dropbox")
      }

     func test_developerDomain() {
          let ext = SystemExtension.make(bundleIdentifier: "com.google.drivefs.Provider")
          XCTAssertEqual(ext.developerDomain, "com.google")
      }

     func test_hasFileLocation_true_with_path() {
          let ext = SystemExtension.make(path: "/Applications/Test.app/Contents/PlugIns/x.appex",
                                         parentBundlePath: "")
          XCTAssertTrue(ext.hasFileLocation)
      }

     func test_hasFileLocation_true_with_parent_bundle() {
          let ext = SystemExtension.make(path: "", parentBundlePath: "/Applications/Test.app")
          XCTAssertTrue(ext.hasFileLocation)
      }

     func test_hasFileLocation_false_for_system_extension() {
          let ext = SystemExtension.make(path: "", parentBundlePath: "", source: .systemExtension)
          XCTAssertFalse(ext.hasFileLocation)
      }

     func test_hashable_consistent() {
          let a = SystemExtension.make(bundleIdentifier: "com.test.foo")
          let b = SystemExtension.make(bundleIdentifier: "com.test.foo")
          XCTAssertEqual(a, b)
          XCTAssertEqual(a.hashValue, b.hashValue)
      }
}
