import SwiftUI
import WidgetKit

/// Shared with the app, which saves the values below (see HomeWidgetSync in
/// lib/state/home_widget_sync.dart).
private let appGroup = "group.com.khathmulqurantracker"

private let emerald = Color(red: 0x09 / 255, green: 0x52 / 255, blue: 0x3A / 255)
private let emeraldLight = Color(red: 0x0D / 255, green: 0x6B / 255, blue: 0x4B / 255)
private let goldLight = Color(red: 0xF0 / 255, green: 0xD6 / 255, blue: 0x8A / 255)

struct KhathmEntry: TimelineEntry {
  let date: Date
  /// Where the reader is up to, e.g. "Al-Baqarah 2:255"; nil before tracking.
  let position: String?
  let percent: Int
  let streak: Int
  let todayVerses: Int

  static let sample = KhathmEntry(
    date: Date(), position: "Al-Baqarah 2:255", percent: 4, streak: 7, todayVerses: 25)
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> KhathmEntry { .sample }

  func getSnapshot(in context: Context, completion: @escaping (KhathmEntry) -> Void) {
    completion(context.isPreview ? .sample : entry(at: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<KhathmEntry>) -> Void) {
    // Today's count resets at midnight, and a streak lapses after a whole
    // day without reading, so show the next day's state from midnight on.
    let now = Date()
    let calendar = Calendar.current
    let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
    completion(
      Timeline(entries: [entry(at: now), entry(at: midnight)], policy: .after(midnight)))
  }

  private func entry(at date: Date) -> KhathmEntry {
    let data = UserDefaults(suiteName: appGroup)
    let format = DateFormatter()
    format.calendar = Calendar(identifier: .gregorian)
    format.locale = Locale(identifier: "en_US_POSIX")
    format.dateFormat = "yyyy-MM-dd"
    let today = format.string(from: date)
    let yesterday = format.string(from: Calendar.current.date(byAdding: .day, value: -1, to: date)!)

    // The streak was counted up to the last day read: it still stands if
    // that was today or yesterday.
    let lastRead = data?.string(forKey: "last_read_day")
    let readToday = lastRead == today
    let streaking = readToday || lastRead == yesterday
    return KhathmEntry(
      date: date,
      position: data?.string(forKey: "position"),
      percent: data?.integer(forKey: "percent") ?? 0,
      streak: streaking ? data?.integer(forKey: "streak") ?? 0 : 0,
      todayVerses: readToday ? data?.integer(forKey: "last_read_verses") ?? 0 : 0)
  }
}

struct KhathmWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: KhathmEntry

  private var today: String {
    switch entry.todayVerses {
    case 0: return "Not read today yet"
    case 1: return "1 verse today"
    default: return "\(entry.todayVerses) verses today"
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Text("🔥 \(entry.streak)")
          .font(.title2.bold())
          .foregroundColor(.white)
        Text(entry.streak > 0 ? "day streak" : "Start a streak today")
          .font(.caption)
          .foregroundColor(goldLight)
          .lineLimit(2)
      }
      Spacer(minLength: 0)
      Text(entry.position ?? "Start tracking your khathm")
        .font(.subheadline.bold())
        .foregroundColor(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      ProgressView(value: Double(entry.percent), total: 100)
        .tint(goldLight)
      Text(family == .systemSmall ? "\(entry.percent)% of khathm" : "\(entry.percent)% of khathm · \(today)")
        .font(.caption2)
        .foregroundColor(.white.opacity(0.8))
        .lineLimit(1)
      if family == .systemSmall {
        Text(today)
          .font(.caption2)
          .foregroundColor(.white.opacity(0.8))
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .widgetBackground(
      LinearGradient(
        colors: [emerald, emeraldLight], startPoint: .topLeading, endPoint: .bottomTrailing))
    // Opens the reader at the tracked verse.
    .widgetURL(URL(string: "khathmtracker://continue?homeWidget"))
  }
}

extension View {
  /// The widget's background, set the way each iOS version expects.
  @ViewBuilder
  func widgetBackground<Background: View>(_ background: Background) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { background }
    } else {
      padding().background(background)
    }
  }
}

@main
struct KhathmWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "KhathmWidget", provider: Provider()) { entry in
      KhathmWidgetView(entry: entry)
    }
    .configurationDisplayName("Khathm progress")
    .description("Your reading streak and how far through your khathm you are.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
