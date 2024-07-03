//
//  SwiftUIView.swift
//  
//
//  Created by Ben Ku on 4/16/24.
//

#if canImport(SwiftUI)
import SwiftUI

// TODO: Add to KuditFrameworks
public extension EdgeInsets {
    static let zero = Self.init(top: 0, leading: 0, bottom: 0, trailing: 0)
}

struct BytesView: View {
    public var label: String?
    var bytes: (any BinaryInteger)?
    var font: Font? = .headline
    var countStyle: ByteCountFormatter.CountStyle? = .file
    var round = false
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 3) {
            if let label {
                Text(label).opacity(0.5) // debugging: "label (\(String(describing: bytes))"
                Spacer()
            }
            if let capacity = bytes {
                let parts = capacity.byteParts(countStyle ?? .file)
                let number = round ? "\(Int(Double(parts.count) ?? -1))" : "\(parts.count)"
                Text(number).font(font)
                if countStyle != nil {
                    Text(parts.units).opacity(0.5)
                }
            }
        }
    }
}

struct StorageBytesView: View {
    var label: String?
    var bytes: (any BinaryInteger)?
    var countStyle: ByteCountFormatter.CountStyle? = .file
    var round = false
    var visible = true
    var body: some View {
        if visible {
            BytesView(label: label, bytes: bytes, countStyle: countStyle, round: round)
        } else {
            EmptyView()
        }
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
public struct StorageInfoView<SomeCurrentDevice: CurrentDevice>: View {
    @ObservedObject public var device: SomeCurrentDevice
    @State var includeDebugInformation: Bool
    public init(device: SomeCurrentDevice, includeDebugInformation: Bool = false) {
        self.device = device
#if os(tvOS)
        // if tvOS, go ahead and expand since interaction is difficult
        self.includeDebugInformation = true
#else
        self.includeDebugInformation = includeDebugInformation
#endif
    }
    
    @State private var width: Double = 0
    
    func width(for capacity: Int64) -> Double {
        let denominator = Double(device.volumeTotalCapacity ?? 1024)
        let percent = Double(capacity) / denominator
        return (1 - percent) * width
    }
    
    @ViewBuilder
    var storageHeader: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Image(symbolName: "internaldrive.fill")
            Text(" Storage").font(.headline)
        }
        .padding()
    }
    
    func backgroundView(color: Color, width: Double) -> some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            RoundedRectangle(cornerRadius: .devicePanelRadius)
                .fill(color)
                .frame(width: width)
        }
    }
    
    /// Invert the capacity to get the value left on the drive
    func inverted(_ capacity: Int64, _ inverted: Bool) -> Int64 {
        inverted ? (device.volumeTotalCapacity ?? 1024 * 1024 * 1024) - capacity : capacity
    }
    
    @ViewBuilder
    func capacityBar(label: String, bytes capacity: Int64?, inverted: Bool = false, color: Color, @ViewBuilder containedContent: @escaping () -> some View) -> some View {
        if let capacity {
            VStack(spacing: 0) {
                containedContent()
                    .background {
                        backgroundView(color: color, width: width(for: capacity))
                    }
                StorageBytesView(label: label, bytes: self.inverted(capacity, inverted), visible: includeDebugInformation)
                    .padding()
            }
        } else {
            containedContent()
        }
    }
    
    @ViewBuilder
    public var storageView: some View {
        capacityBar(label: "Volume Available Capacity:", bytes: device.volumeAvailableCapacity, color: .green) {
            capacityBar(label: "Available for Opportunistic:", bytes: device.volumeAvailableCapacityForOpportunisticUsage, color: .yellow) {
                capacityBar(label: "Available for Important:", bytes: device.volumeAvailableCapacityForImportantUsage, color: .red) {
                    capacityBar(label: "Used Capacity:", bytes: device.volumeAvailableCapacityForImportantUsage, inverted: true, color: .clear) {
                        HStack(spacing: 0) {
                            storageHeader
                            Spacer()
                            HStack(spacing: 0) {
                                if includeDebugInformation {
                                    Text("Total Capacity: ").font(.caption.smallCaps()).opacity(0.5)
                                    StorageBytesView(bytes: device.volumeTotalCapacity)
                                } else {
                                    BytesView(bytes: device.volumeAvailableCapacity, countStyle: nil, round: true)
                                    Text(" / ").font(.headline)
                                    StorageBytesView(bytes: device.volumeTotalCapacity, round: true)
                                }
                            }.padding()
                        }
                    }
                }
            }
        }
        .background {
            backgroundView(color: .gray, width: width(for: 0))
        }
        .font(.caption)
        .foregroundStyle(.black)
        // Store width for percent calculations.  TODO: create this as a reusable modele for having percentage based dimensions...
        .overlay(GeometryReader { proxy in
            Color.clear
                .onAppear {
                    self.width = proxy.size.width
                }
                .backport.onChange(of: proxy.size.width) {
                    self.width = proxy.size.width
                }
        })
    }
    
    public var body: some View {
#if os(tvOS)
        storageView
#else
        storageView
            .onTapGesture {
                withAnimation {
                    includeDebugInformation.toggle()
                }
            }
#endif
    }
}

#if swift(>=5.9)
@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("Storage Info") {
    List {
        BytesView(label: "Test", bytes: 1_000_000, font: .title, countStyle: .memory)
            .padding()
        StorageInfoView(device: Device.current)
        StorageInfoView(device: Device.current, includeDebugInformation: true)
        ForEach(MockDevice.mocks) { mock in
            StorageInfoView(device: mock)
        }
        Spacer()
    }
    .padding()
}
#endif
#endif
