import SwiftUI

public struct EngramLogoView: View {
    public var size: CGFloat
    public var primaryColor: Color
    public var traceColor: Color

    public init(
        size: CGFloat = 24,
        primaryColor: Color = Color(red: 0.85, green: 0.60, blue: 0.47), // #D99A78
        traceColor: Color = Color(red: 0.07, green: 0.07, blue: 0.06)   // #111110
    ) {
        self.size = size
        self.primaryColor = primaryColor
        self.traceColor = traceColor
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let scale = canvasSize.width / 512.0

            // 1. Folded lowercase e main body
            var bodyPath = Path()
            bodyPath.move(to: CGPoint(x: 424 * scale, y: 80 * scale))
            bodyPath.addLine(to: CGPoint(x: 224 * scale, y: 80 * scale))
            bodyPath.addCurve(
                to: CGPoint(x: 40 * scale, y: 264 * scale),
                control1: CGPoint(x: 122.4 * scale, y: 80 * scale),
                control2: CGPoint(x: 40 * scale, y: 162.4 * scale)
            )
            bodyPath.addCurve(
                to: CGPoint(x: 224 * scale, y: 448 * scale),
                control1: CGPoint(x: 40 * scale, y: 365.6 * scale),
                control2: CGPoint(x: 122.4 * scale, y: 448 * scale)
            )
            bodyPath.addLine(to: CGPoint(x: 424 * scale, y: 448 * scale))
            bodyPath.addLine(to: CGPoint(x: 424 * scale, y: 384 * scale))
            bodyPath.addLine(to: CGPoint(x: 224 * scale, y: 384 * scale))
            bodyPath.addCurve(
                to: CGPoint(x: 104 * scale, y: 264 * scale),
                control1: CGPoint(x: 157.7 * scale, y: 384 * scale),
                control2: CGPoint(x: 104 * scale, y: 330.3 * scale)
            )
            bodyPath.addCurve(
                to: CGPoint(x: 224 * scale, y: 144 * scale),
                control1: CGPoint(x: 104 * scale, y: 197.7 * scale),
                control2: CGPoint(x: 157.7 * scale, y: 144 * scale)
            )
            bodyPath.addLine(to: CGPoint(x: 360 * scale, y: 144 * scale))
            bodyPath.addLine(to: CGPoint(x: 360 * scale, y: 224 * scale))
            bodyPath.addLine(to: CGPoint(x: 208 * scale, y: 224 * scale))
            bodyPath.addLine(to: CGPoint(x: 208 * scale, y: 288 * scale))
            bodyPath.addLine(to: CGPoint(x: 424 * scale, y: 288 * scale))
            bodyPath.closeSubpath()

            context.fill(bodyPath, with: .color(primaryColor))

            // 2. Continuous memory traces
            var trace1 = Path()
            trace1.move(to: CGPoint(x: 403 * scale, y: 101 * scale))
            trace1.addLine(to: CGPoint(x: 224 * scale, y: 101 * scale))
            trace1.addCurve(
                to: CGPoint(x: 61 * scale, y: 264 * scale),
                control1: CGPoint(x: 134 * scale, y: 101 * scale),
                control2: CGPoint(x: 61 * scale, y: 174 * scale)
            )
            trace1.addCurve(
                to: CGPoint(x: 224 * scale, y: 427 * scale),
                control1: CGPoint(x: 61 * scale, y: 354 * scale),
                control2: CGPoint(x: 134 * scale, y: 427 * scale)
            )
            trace1.addLine(to: CGPoint(x: 424 * scale, y: 427 * scale))

            var trace2 = Path()
            trace2.move(to: CGPoint(x: 382 * scale, y: 122 * scale))
            trace2.addLine(to: CGPoint(x: 224 * scale, y: 122 * scale))
            trace2.addCurve(
                to: CGPoint(x: 82 * scale, y: 264 * scale),
                control1: CGPoint(x: 145.6 * scale, y: 122 * scale),
                control2: CGPoint(x: 82 * scale, y: 185.6 * scale)
            )
            trace2.addCurve(
                to: CGPoint(x: 224 * scale, y: 406 * scale),
                control1: CGPoint(x: 82 * scale, y: 342.4 * scale),
                control2: CGPoint(x: 145.6 * scale, y: 406 * scale)
            )
            trace2.addLine(to: CGPoint(x: 424 * scale, y: 406 * scale))

            var cross1 = Path()
            cross1.move(to: CGPoint(x: 403 * scale, y: 102 * scale))
            cross1.addLine(to: CGPoint(x: 403 * scale, y: 267 * scale))
            cross1.addLine(to: CGPoint(x: 208 * scale, y: 267 * scale))

            var cross2 = Path()
            cross2.move(to: CGPoint(x: 382 * scale, y: 123 * scale))
            cross2.addLine(to: CGPoint(x: 382 * scale, y: 246 * scale))
            cross2.addLine(to: CGPoint(x: 208 * scale, y: 246 * scale))

            let strokeStyle = StrokeStyle(lineWidth: max(1.0, 5.0 * scale), lineCap: .round, lineJoin: .round)
            context.stroke(trace1, with: .color(traceColor), style: strokeStyle)
            context.stroke(trace2, with: .color(traceColor), style: strokeStyle)
            context.stroke(cross1, with: .color(traceColor), style: strokeStyle)
            context.stroke(cross2, with: .color(traceColor), style: strokeStyle)
        }
        .frame(width: size, height: size)
    }
}
