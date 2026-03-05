//
//  RangeBoundsSlider.swift
//  Randomizer
//
//  Created by Дмитрий Дементьев on 05.03.2026.
//

import SwiftUI

/// Двухползунковый слайдер для выбора двух границ диапазона.
///
/// Используется в настройках индикатора рандомайзера:
/// - левая ручка задаёт `Граница 1`
/// - правая ручка задаёт `Граница 2`
/// - ручки не пересекаются (минимальный зазор = 1)
struct RangeBoundsSlider: View {
    let minimumValue: Int
    let maximumValue: Int
    let lowerValue: Int
    let upperValue: Int
    let onChange: (_ lower: Int, _ upper: Int) -> Void

    private let handleSize: CGFloat = 14
    private let trackHeight: CGFloat = 4
    private let sliderCoordinateSpace = "range-bounds-slider-space"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geometry in
                let width = max(1, geometry.size.width - handleSize)
                let lowerX = xPosition(for: lowerValue, width: width)
                let upperX = xPosition(for: upperValue, width: width)

                ZStack(alignment: .topLeading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.22))
                        .frame(height: trackHeight)
                        .offset(x: handleSize / 2, y: (handleSize - trackHeight) / 2)

                    Capsule()
                        .fill(Color.accentColor.opacity(0.9))
                        .frame(width: max(0, upperX - lowerX), height: trackHeight)
                        .offset(x: lowerX + handleSize / 2, y: (handleSize - trackHeight) / 2)

                    handle
                        .position(x: lowerX + handleSize / 2, y: handleSize / 2)
                        .gesture(lowerDragGesture(width: width))

                    handle
                        .position(x: upperX + handleSize / 2, y: handleSize / 2)
                        .gesture(upperDragGesture(width: width))
                }
            }
            .frame(height: handleSize)
            .coordinateSpace(name: sliderCoordinateSpace)

            HStack(spacing: 8) {
                valueChip(lowerValue)
                Spacer()
                Text("0...99")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
                valueChip(upperValue)
            }
        }
    }

    private var handle: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: handleSize, height: handleSize)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 1)
    }

    private func valueChip(_ value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: 11, weight: .semibold))
            .monospacedDigit()
            .foregroundColor(.primary)
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.16))
            )
    }

    private func lowerDragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(sliderCoordinateSpace))
            .onChanged { gesture in
                let value = valueForDragLocation(gesture.location.x, width: width)
                let newLower = min(value, upperValue - 1)
                onChange(max(minimumValue, newLower), upperValue)
            }
    }

    private func upperDragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(sliderCoordinateSpace))
            .onChanged { gesture in
                let value = valueForDragLocation(gesture.location.x, width: width)
                let newUpper = max(value, lowerValue + 1)
                onChange(lowerValue, min(maximumValue, newUpper))
            }
    }

    private func xPosition(for value: Int, width: CGFloat) -> CGFloat {
        let clampedValue = min(max(value, minimumValue), maximumValue)
        let ratio = CGFloat(clampedValue - minimumValue) / CGFloat(maximumValue - minimumValue)
        return ratio * width
    }

    private func valueForDragLocation(_ locationX: CGFloat, width: CGFloat) -> Int {
        let clampedX = min(max(0, locationX - handleSize / 2), width)
        let ratio = clampedX / width
        let value = CGFloat(minimumValue) + ratio * CGFloat(maximumValue - minimumValue)
        return Int(round(value))
    }
}
