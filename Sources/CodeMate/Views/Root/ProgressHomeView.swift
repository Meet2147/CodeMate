import SwiftUI
import SwiftData

struct ProgressHomeView: View {
    @Environment(\.colorScheme) private var scheme
    @Query private var progressRecords: [ProblemProgress]

    private var solvedIds: Set<String> { Set(progressRecords.filter { $0.status == .solved }.map(\.problemId)) }
    private var inProgressIds: Set<String> { Set(progressRecords.filter { $0.status == .inProgress }.map(\.problemId)) }

    private var solvedCount: Int { solvedIds.count }
    private var inProgressCount: Int { inProgressIds.count }
    private var totalCount: Int { ProblemBank.all.count }

    private var byTopic: [(Topic, Int, Int)] {
        Topic.allCases.map { topic in
            let inTopic = ProblemBank.all.filter { $0.topics.contains(topic) }
            let solved = inTopic.filter { solvedIds.contains($0.id) }.count
            return (topic, solved, inTopic.count)
        }.filter { $0.2 > 0 }
    }

    private var byCompany: [(Company, Int, Int)] {
        Company.allCases.map { company in
            let inCompany = ProblemBank.all.filter { $0.companies.contains(company) }
            let solved = inCompany.filter { solvedIds.contains($0.id) }.count
            return (company, solved, inCompany.count)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("My Progress")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(CMTheme.textPrimary(scheme))

                HStack(spacing: 14) {
                    statTile(title: "Solved", value: "\(solvedCount)", total: totalCount, color: CMTheme.success)
                    statTile(title: "In Progress", value: "\(inProgressCount)", total: totalCount, color: CMTheme.warning)
                    statTile(title: "Not Started", value: "\(max(0, totalCount - solvedCount - inProgressCount))", total: totalCount, color: CMTheme.textSecondary(scheme))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("BY TARGET COMPANY").font(.system(size: 10, weight: .bold)).foregroundStyle(CMTheme.textSecondary(scheme))
                    ForEach(byCompany, id: \.0) { company, solved, total in
                        progressRow(label: company.rawValue, solved: solved, total: total, color: CMTheme.companyColor(company))
                    }
                }
                .neumorphicRaised(padding: 16)

                VStack(alignment: .leading, spacing: 10) {
                    Text("BY TOPIC").font(.system(size: 10, weight: .bold)).foregroundStyle(CMTheme.textSecondary(scheme))
                    ForEach(byTopic, id: \.0) { topic, solved, total in
                        progressRow(label: topic.rawValue, solved: solved, total: total, color: CMTheme.accent)
                    }
                }
                .neumorphicRaised(padding: 16)
            }
            .padding(24)
        }
        .background(CMTheme.base(scheme))
    }

    private func statTile(title: String, value: String, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(CMTheme.textSecondary(scheme))
            Text(value).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(color)
            Text("of \(total) problems").font(.system(size: 10)).foregroundStyle(CMTheme.textSecondary(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .neumorphicRaised(padding: 16)
    }

    private func progressRow(label: String, solved: Int, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(CMTheme.textPrimary(scheme))
                Spacer()
                Text("\(solved)/\(total)").font(.system(size: 11, weight: .semibold)).foregroundStyle(CMTheme.textSecondary(scheme))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(CMTheme.shadowDark(scheme).opacity(0.3)).frame(height: 6)
                    Capsule().fill(color.gradient)
                        .frame(width: total == 0 ? 0 : geo.size.width * CGFloat(solved) / CGFloat(total), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
