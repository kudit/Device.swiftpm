import SwiftUI
import Device

#Preview("Capabilities") {
    VStack {
        HStack {
            Image(symbolName: "star")
            Image(symbolName: "dynamicisland")
            Image(symbolName: "bad")
        }
        .symbolRenderingMode(.hierarchical)
        Label("Foo", symbolName: "star.fill")
        Label("Bar", symbolName: "roundedcorners")
        Label("Baz", symbolName: "bad")
        Divider()
        CapabilitiesTextView(capabilities: Set(Capability.allCases))
    }
    .font(.largeTitle)
    .padding()
    .padding()
    .padding()
    .padding()
    .padding()
}

extension CGFloat {
    static var defaultFontSize: CGFloat = 44
}

struct SymbolTests<T: DeviceAttributeExpressible>: View {
    @State var attribute: T
    var size: CGFloat = .defaultFontSize
    var body: some View {
        HStack {
            ZStack {
                Color.clear
                Image(attribute)
            }
            ZStack {
                Color.clear
                Image(attribute)
                    .symbolRenderingMode(.hierarchical)
            }
            ZStack {
                Color.clear
                Image(attribute)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red, .green, .blue)
            }
            ZStack {
                Color.clear
                Image(attribute)
                    .symbolRenderingMode(.multicolor)
            }
        }
        .font(.system(size: size))
    }
}

struct AttributeListView<T: DeviceAttributeExpressible>: View {
    @State var header: String
    @State var attributes: [T]
    var styleView = false
    var size: CGFloat = .defaultFontSize
    var body: some View {
        Section {
            ForEach(attributes, id: \.self) { attribute in
                let label = Label(attribute.label, symbolName: attribute.symbolName)
                    .foregroundColor(.primary)
                    .font(.headline)
                if styleView {
                    SymbolTests(attribute: attribute, size: size)
                } else {
                    if attribute.test(device: Device.current) {
                        label
                            .listRowBackground(attribute.color)
                    } else {
                        label
                    }
                }
            }
        } header: {
            Text(header)
        }
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
struct HardwareListView: View {
    @State var styleView = false
    @State var size: CGFloat = .defaultFontSize
    init(styleView: Bool = false, size: CGFloat = .defaultFontSize) {
        self.styleView = styleView
        self.size = size
//        // This is triggered on main view for some reason.
//        Device.current.enableMonitoring(frequency: 10)
    }
    var body: some View {
        List {
            Section {
                DeviceInfoView(device: Device.current)
                ZStack(alignment: .topLeading) {
                    Color.clear
                    Text(Device.current.description).padding()
                }
                .foregroundStyle(.background)
                .background {
                    RoundedRectangle(cornerRadius: 15)
                }

            } footer: {
                VStack {
                    Spacer()
                    Divider()
                    Spacer()
                    Picker("View", selection: $styleView) {
                        Text("Names").tag(false)
                        Text("Styles").tag(true)
                    }
                    .pickerStyle(.segmentedBackport)
                    if styleView {
                        #if !os(tvOS)
                        Slider(
                            value: $size,
                            in: 9...100
                        )
                        #endif
                    }
                }
            }
            AttributeListView(header: "Idioms", attributes: Device.Idiom.allCases, styleView: styleView, size: size)
            AttributeListView(header: "Environments", attributes: Device.Environment.allCases, styleView: styleView, size: size)
            AttributeListView(header: "Capabilities", attributes: Capability.allCases, styleView: styleView, size: size)
        }
        .navigationTitle("Hardware")
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("HardwareList") {
    HardwareListView()
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("DeviceList") {
    DeviceListView(devices: Device.all)
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
public struct DeviceTestView: View {
    @State var disableIdleTimer = false

    var environments: some View {
        HStack {
            ForEach(Device.Environment.allCases, id: \.self) { environment in
                let enabled = environment.test(device: Device.current)
                Image(environment)
                    .opacity(enabled ? 1.0 : 0.2)
                    .foregroundColor(enabled ? environment.color : .primary)
                    .accessibilityLabel((enabled ? "Is" : "Not") + " " + environment.label)
            }
        }
    }

    var testView: some View {
        List {
            Section {
                NavigationLink {
                    BatteryTestsView()
                } label: {
                    MonitoredBatteryView(battery: Device.current.battery, fontSize: 80)
                }
#if os(iOS) // only works on iOS so don't show on other devices.
                Toggle("Disable Idle Timer", isOn: Binding(get: {
                    return disableIdleTimer 
                }, set: { newValue in
                    disableIdleTimer = newValue
                    Device.current.isIdleTimerDisabled = newValue
                }))
#endif
            } header: {
                Text("Battery")
            }
            Section("Environment") {
                NavigationLink {
                    List {
                        AttributeListView(header: "Environments", attributes: Device.Environment.allCases)
                    }
                } label: {
                    HStack {
                        Spacer()
                        environments
                        Spacer()
                    }
                }
            }
            Section {
                NavigationLink(destination: {
                    HardwareListView()
                }, label: {
                    CurrentDeviceInfoView(device: Device.current)
                })
            } header: {
                Text("Current Device")
            } footer: {
                HStack {
                    Spacer()
                    Text(verbatim: "© \(Calendar.current.component(.year, from: Date())) Kudit, LLC")
                }
            }
        }
        .navigationTitle("Device.swift v\(Device.version)")
        .toolbar {
            NavigationLink(destination: {
                DeviceListView(devices: Device.all)
                    .toolbar {
                        if Device.current.isSimulator {
                            Button("Migrate") {
                                migrateContent()
                            }
                        }
                    }
            }, label: {
                Text("All Devices")
                    .font(.headline)
            })
        }
    }
    
    public var body: some View {
        BackportNavigationStack {
            testView
        }
    }
    
    /// For testing and migrating code during development.
    func migrateContent() {
        Migration.migrate()
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview {
    DeviceTestView()
}
