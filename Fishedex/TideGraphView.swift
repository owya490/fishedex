import SwiftUI

struct TideGraphView: View {
    let locationName: String
    let samples: [TideSample]
    let extrema: [TideExtreme]

    private let graphHeight: CGFloat = 168
    private let yAxisWidth: CGFloat = 38
    private let xAxisHeight: CGFloat = 22

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(locationName.uppercased())
                    .font(FishedexFont.micro)
                    .foregroundStyle(FishedexTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Text("TIDE GRAPH")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.ink)
                    .kerning(0.6)
            }

            HStack(alignment: .top, spacing: 6) {
                yAxis
                VStack(spacing: 4) {
                    graphCanvas
                    xAxis
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder(lineWidth: 1)
    }

    private var yAxis: some View {
        VStack {
            Text(heightLabel(maxHeight))
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.muted)

            Spacer()

            Text("HEIGHT")
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.muted)
                .kerning(0.4)
                .rotationEffect(.degrees(-90))
                .fixedSize()

            Spacer()

            Text(heightLabel(minHeight))
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.muted)
        }
        .frame(width: yAxisWidth, height: graphHeight)
    }

    private var xAxis: some View {
        HStack(spacing: 0) {
            ForEach(Array(stride(from: 0, through: 24, by: 2)), id: \.self) { hour in
                Text("\(hour)")
                    .font(FishedexFont.micro)
                    .foregroundStyle(FishedexTheme.muted)
                    .frame(maxWidth: .infinity)
            }
        }
        .overlay(alignment: .leading) {
            Text("HOUR:")
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.muted)
                .offset(x: -yAxisWidth - 6)
        }
        .frame(height: xAxisHeight)
    }

    private var graphCanvas: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let dayStart = Calendar.current.startOfDay(for: Date())
            let points = chartPoints(in: size, dayStart: dayStart)
            let markers = markerPoints(in: size, dayStart: dayStart)

            ZStack {
                Rectangle()
                    .fill(FishedexTheme.card)

                grid(in: size)

                if points.count >= 2 {
                    filledArea(points: points, height: size.height)
                    curveLine(points: points)
                }

                ForEach(markers) { marker in
                    markerLayer(marker, canvasHeight: size.height)
                }

                if let nowX = currentTimeX(in: size, dayStart: dayStart) {
                    Path { path in
                        path.move(to: CGPoint(x: nowX, y: 0))
                        path.addLine(to: CGPoint(x: nowX, y: size.height))
                    }
                    .stroke(FishedexTheme.coral.opacity(0.75), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
        }
        .frame(height: graphHeight)
        .fishedexBorder(lineWidth: 1, color: FishedexTheme.softLine)
    }

    private func grid(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let horizontalLines = 4
            let verticalLines = 12

            for index in 0...horizontalLines {
                let y = canvasSize.height * CGFloat(index) / CGFloat(horizontalLines)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                context.stroke(path, with: .color(FishedexTheme.softLine), lineWidth: 1)
            }

            for index in 0...verticalLines {
                let x = canvasSize.width * CGFloat(index) / CGFloat(verticalLines)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: canvasSize.height))
                context.stroke(path, with: .color(FishedexTheme.softLine), lineWidth: 1)
            }
        }
    }

    private func filledArea(points: [CGPoint], height: CGFloat) -> some View {
        Path { path in
            guard let first = points.first, let last = points.last else { return }
            path.move(to: CGPoint(x: first.x, y: height))
            path.addLine(to: first)
            for index in 1..<points.count {
                let previous = points[index - 1]
                let current = points[index]
                let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
                path.addQuadCurve(to: midpoint, control: previous)
            }
            if let lastPoint = points.last {
                path.addLine(to: lastPoint)
            }
            path.addLine(to: CGPoint(x: last.x, y: height))
            path.closeSubpath()
        }
        .fill(FishedexTheme.ocean.opacity(0.35))
    }

    private func curveLine(points: [CGPoint]) -> some View {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for index in 1..<points.count {
                let previous = points[index - 1]
                let current = points[index]
                let midpoint = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
                path.addQuadCurve(to: midpoint, control: previous)
            }
            if let last = points.last {
                path.addLine(to: last)
            }
        }
        .stroke(FishedexTheme.ocean, lineWidth: 2)
    }

    private func markerLayer(_ marker: TideMarker, canvasHeight: CGFloat) -> some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: marker.x, y: marker.y))
                path.addLine(to: CGPoint(x: marker.x, y: canvasHeight))
            }
            .stroke(FishedexTheme.ocean.opacity(0.55), lineWidth: 1)

            Circle()
                .fill(FishedexTheme.ocean)
                .frame(width: 7, height: 7)
                .position(x: marker.x, y: marker.y)

            Text(marker.label)
                .font(FishedexFont.micro)
                .foregroundStyle(FishedexTheme.ink)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.92))
                .fishedexBorder(lineWidth: 1, color: FishedexTheme.ocean.opacity(0.35))
                .position(x: marker.x, y: marker.labelY)
        }
    }

    // MARK: - Layout math

    private var rawMinHeight: Double {
        let sampleMin = samples.map(\.heightMeters).min() ?? 0
        let extremaMin = extrema.map(\.heightMeters).min() ?? sampleMin
        return min(sampleMin, extremaMin)
    }

    private var rawMaxHeight: Double {
        let sampleMax = samples.map(\.heightMeters).max() ?? 1
        let extremaMax = extrema.map(\.heightMeters).max() ?? sampleMax
        return max(sampleMax, extremaMax)
    }

    private var displayRange: Double {
        max(rawMaxHeight - rawMinHeight, 0.2)
    }

    private var minHeight: Double {
        max(0, rawMinHeight - displayRange * 0.08)
    }

    private var maxHeight: Double {
        rawMaxHeight + displayRange * 0.08
    }

    private func heightLabel(_ value: Double) -> String {
        String(format: "%.2f M", value)
    }

    private func chartPoints(in size: CGSize, dayStart: Date) -> [CGPoint] {
        samples.map { sample in
            CGPoint(
                x: xPosition(for: sample.time, dayStart: dayStart, width: size.width),
                y: yPosition(for: sample.heightMeters, height: size.height)
            )
        }
    }

    private func markerPoints(in size: CGSize, dayStart: Date) -> [TideMarker] {
        let sorted = extrema.sorted { $0.time < $1.time }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        fmt.timeZone = .current

        return sorted.enumerated().map { index, tide in
            let x = xPosition(for: tide.time, dayStart: dayStart, width: size.width)
            let y = yPosition(for: tide.heightMeters, height: size.height)
            let labelY = max(10, y - (tide.isHigh ? 16 : 10) - CGFloat(index % 2) * 8)
            return TideMarker(
                id: tide.id,
                x: x,
                y: y,
                label: fmt.string(from: tide.time),
                labelY: labelY
            )
        }
    }

    private func currentTimeX(in size: CGSize, dayStart: Date) -> CGFloat? {
        let now = Date()
        guard Calendar.current.isDateInToday(now) else { return nil }
        return xPosition(for: now, dayStart: dayStart, width: size.width)
    }

    private func xPosition(for time: Date, dayStart: Date, width: CGFloat) -> CGFloat {
        let elapsed = time.timeIntervalSince(dayStart)
        let fraction = max(0, min(1, elapsed / (24 * 3600)))
        return CGFloat(fraction) * width
    }

    private func yPosition(for height: Double, height canvasHeight: CGFloat) -> CGFloat {
        let span = max(maxHeight - minHeight, 0.2)
        let normalized = (height - minHeight) / span
        let clamped = max(0, min(1, normalized))
        return canvasHeight - CGFloat(clamped) * canvasHeight
    }
}

private struct TideMarker: Identifiable {
    let id: String
    let x: CGFloat
    let y: CGFloat
    let label: String
    let labelY: CGFloat
}
