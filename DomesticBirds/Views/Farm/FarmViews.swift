import SwiftUI

// MARK: - Farm Navigation Hub
struct FarmNavigationView: View {
    var body: some View {
        NavigationView {
            FarmHubView()
        }
    }
}

struct FarmHubView: View {
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(FarmSection.allSections) { section in
                    NavigationLink(destination: section.destination) {
                        FarmHubCard(section: section)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
        }
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle("Farm")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct FarmSection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: AnyView

    static var allSections: [FarmSection] {[
        FarmSection(id: "groups", title: "Groups", subtitle: "Manage your flock groups", icon: "person.3.fill",
                    color: Color(hex: "#52A865"), destination: AnyView(GroupsView())),
        FarmSection(id: "eggs", title: "Egg Production", subtitle: "Track daily egg counts", icon: "circle.fill",
                    color: Color(hex: "#E8A020"), destination: AnyView(EggProductionView())),
        FarmSection(id: "breeding", title: "Breeding", subtitle: "Manage breeding pairs", icon: "heart.fill",
                    color: Color(hex: "#805AD5"), destination: AnyView(BreedingView())),
        FarmSection(id: "feeding", title: "Feeding", subtitle: "Record feed usage", icon: "bag.fill",
                    color: Color(hex: "#7B4F2E"), destination: AnyView(FeedingView())),
        FarmSection(id: "health", title: "Health", subtitle: "Bird health records", icon: "cross.circle.fill",
                    color: Color(hex: "#E53E3E"), destination: AnyView(HealthView())),
        FarmSection(id: "housing", title: "Housing", subtitle: "Coops & enclosures", icon: "house.fill",
                    color: Color(hex: "#3A9BD5"), destination: AnyView(HousingView())),
        FarmSection(id: "reports", title: "Reports", subtitle: "Analytics & insights", icon: "chart.bar.fill",
                    color: Color(hex: "#38B2AC"), destination: AnyView(ReportsView())),
        FarmSection(id: "activity", title: "Activity Log", subtitle: "History of all actions", icon: "clock.fill",
                    color: Color(hex: "#A09E98"), destination: AnyView(ActivityHistoryView())),
    ]}
}

struct FarmHubCard: View {
    let section: FarmSection
    @Environment(\.colorScheme) var scheme
    @State private var pressed = false

    var body: some View {
        DBCard {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle().fill(section.color.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: section.icon).font(.system(size: 20)).foregroundColor(section.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title).font(DBFont.headline(15)).foregroundColor(AdaptiveColor.text(scheme))
                    Text(section.subtitle).font(DBFont.label(11)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scaleEffect(pressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
    }
}

// MARK: - Groups View
struct GroupsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @State private var showAdd = false
    @State private var groupToDelete: BirdGroup? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            if appState.groups.isEmpty {
                EmptyStateView(icon: "🐓", title: "No Groups", message: "Create groups to organize your birds",
                               action: { showAdd = true }, actionLabel: "Add Group")
                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
            } else {
                ForEach(appState.groups) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        GroupRow(group: group)
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { groupToDelete = group; showDeleteConfirm = true }
                        label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle("Groups")
        .navigationBarItems(trailing: Button(action: { showAdd = true }) {
            Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.dbGreen)
        })
        .sheet(isPresented: $showAdd) { AddGroupView() }
        .alert("Delete Group?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { if let g = groupToDelete { appState.deleteGroup(g) } }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct GroupRow: View {
    let group: BirdGroup
    @Environment(\.colorScheme) var scheme

    var body: some View {
        DBCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(group.purpose.color.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "person.3.fill").foregroundColor(group.purpose.color).font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name).font(DBFont.headline(15)).foregroundColor(AdaptiveColor.text(scheme))
                    HStack(spacing: 8) {
                        TagChip(text: group.purpose.rawValue, color: group.purpose.color)
                        Text("\(group.birdCount) birds").font(DBFont.label(12)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(AdaptiveColor.textSecondary(scheme)).font(.system(size: 13))
            }
            .padding(14)
        }
    }
}

struct AddGroupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @Environment(\.colorScheme) var scheme
    @State private var name = ""
    @State private var purpose: GroupPurpose = .layers
    @State private var birdCount = ""
    @State private var notes = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    FormSection(title: "Group Info") {
                        DBTextField(placeholder: "Group name *", text: $name, icon: "person.3")
                        DBTextField(placeholder: "Number of birds", text: $birdCount, icon: "bird", keyboardType: .numberPad)
                    }
                    FormSection(title: "Purpose") {
                        VStack(spacing: 8) {
                            ForEach(GroupPurpose.allCases, id: \.self) { p in
                                Button(action: { purpose = p }) {
                                    HStack {
                                        Circle().fill(p.color).frame(width: 10, height: 10)
                                        Text(p.rawValue).font(DBFont.body()).foregroundColor(AdaptiveColor.text(scheme))
                                        Spacer()
                                        if purpose == p {
                                            Image(systemName: "checkmark.circle.fill").foregroundColor(p.color)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    FormSection(title: "Notes") {
                        DBTextField(placeholder: "Notes (optional)", text: $notes, icon: "note.text")
                    }
                    if showError { Text("Group name is required").font(DBFont.caption()).foregroundColor(.red) }
                    DBButton("Create Group", icon: "plus.circle.fill") {
                        guard !name.isEmpty else { showError = true; return }
                        let group = BirdGroup(name: name, purpose: purpose, birdCount: Int(birdCount) ?? 0, notes: notes)
                        appState.addGroup(group)
                        dismiss.wrappedValue.dismiss()
                    }
                }
                .padding(16)
            }
            .background(AdaptiveColor.background(scheme).ignoresSafeArea())
            .navigationTitle("Add Group")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss.wrappedValue.dismiss() })
        }
    }
}

struct GroupDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    let group: BirdGroup

    var groupBirds: [MyBird] { appState.myBirds.filter { $0.groupId == group.id } }
    var groupEggs: [EggRecord] { appState.eggRecords.filter { $0.groupId == group.id } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [group.purpose.color, group.purpose.color.opacity(0.7)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    VStack(spacing: 8) {
                        Image(systemName: "person.3.fill").font(.system(size: 40)).foregroundColor(.white)
                        Text(group.name).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(.white)
                        TagChip(text: group.purpose.rawValue, color: .white)
                    }
                    .padding(24)
                }
                .frame(height: 160)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Birds in Group", value: "\(groupBirds.count)", icon: "bird.fill", color: .dbGreen)
                    StatCard(title: "Egg Records", value: "\(groupEggs.count)", icon: "circle.fill", color: Color(hex: "#E8A020"))
                }

                if !groupBirds.isEmpty {
                    DBCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Birds").font(DBFont.headline()).foregroundColor(AdaptiveColor.text(scheme))
                            ForEach(groupBirds.prefix(5)) { bird in
                                HStack {
                                    Text(bird.type.icon)
                                    Text(bird.name).font(DBFont.caption(14)).foregroundColor(AdaptiveColor.text(scheme))
                                    Spacer()
                                    HealthBadge(status: bird.healthStatus)
                                }
                            }
                            if groupBirds.count > 5 {
                                Text("+ \(groupBirds.count - 5) more").font(DBFont.label()).foregroundColor(.dbGreen)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .padding(16)
        }
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Egg Production
struct EggProductionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @State private var showAdd = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Today", value: "\(appState.totalEggsToday)", icon: "circle.fill", color: Color(hex: "#E8A020"))
                    StatCard(title: "This Week", value: "\(appState.totalEggsThisWeek)", icon: "calendar", color: .dbGreen)
                }

                // Chart
                if !appState.eggRecords.isEmpty {
                    DBCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Last 7 Days").font(DBFont.headline()).foregroundColor(AdaptiveColor.text(scheme))
                            SparklineChart(values: appState.eggsForLast7Days(), color: Color(hex: "#E8A020"))
                                .frame(height: 80)
                            HStack {
                                ForEach(0..<7) { i in
                                    let day = Calendar.current.date(byAdding: .day, value: -(6-i), to: Date()) ?? Date()
                                    Text(day, formatter: shortDayFormatter)
                                        .font(DBFont.label(10))
                                        .foregroundColor(AdaptiveColor.textSecondary(scheme))
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(16)
                    }
                }

                // Records list
                SectionHeader(title: "All Records")

                if appState.eggRecords.isEmpty {
                    EmptyStateView(icon: "🥚", title: "No Egg Records", message: "Start tracking your daily egg production",
                                   action: { showAdd = true }, actionLabel: "Add Record")
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(appState.eggRecords.sorted { $0.date > $1.date }) { record in
                            EggRecordRow(record: record) {
                                appState.deleteEggRecord(record)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle("Egg Production")
        .navigationBarItems(trailing: Button(action: { showAdd = true }) {
            Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(Color(hex: "#E8A020"))
        })
        .sheet(isPresented: $showAdd) { AddEggRecordView() }
    }
}

var shortDayFormatter: DateFormatter = {
    let f = DateFormatter(); f.dateFormat = "EEE"; return f
}()

struct EggRecordRow: View {
    let record: EggRecord
    let onDelete: () -> Void
    @Environment(\.colorScheme) var scheme
    @State private var showDeleteConfirm = false

    var body: some View {
        DBCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color(hex: "#E8A020").opacity(0.12)).frame(width: 44, height: 44)
                    Text("🥚").font(.system(size: 22))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.groupName).font(DBFont.headline(14)).foregroundColor(AdaptiveColor.text(scheme))
                    Text(record.date, style: .date).font(DBFont.label(12)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(record.count)").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(Color(hex: "#E8A020"))
                    Text("eggs").font(DBFont.label(11)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                }
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash").font(.system(size: 14)).foregroundColor(.red.opacity(0.6))
                }
            }
            .padding(14)
        }
        .dbConfirmDelete(isPresented: $showDeleteConfirm, itemName: "Egg Record", action: onDelete)
    }
}

struct AddEggRecordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @Environment(\.colorScheme) var scheme
    @State private var selectedGroup: BirdGroup? = nil
    @State private var count = ""
    @State private var brokenCount = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    formContent
                    if showError {
                        Text("Egg count is required").foregroundColor(.red).font(DBFont.caption())
                    }
                    DBButton("Save Record", icon: "checkmark.circle.fill", action: saveRecord)
                }
                .padding(16)
            }
            .background(AdaptiveColor.background(scheme).ignoresSafeArea())
            .navigationTitle("Add Egg Record")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss.wrappedValue.dismiss() })
        }
    }

    @ViewBuilder private var formContent: some View {
        FormSection(title: "Egg Record") {
            if !appState.groups.isEmpty {
                groupPicker
            }
            DBTextField(placeholder: "Egg count *", text: $count, icon: "circle.fill", keyboardType: .numberPad)
            DBTextField(placeholder: "Broken eggs", text: $brokenCount, icon: "xmark.circle", keyboardType: .numberPad)
            datePicker
        }
    }

    @ViewBuilder private var groupPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Group").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
            Picker("Group", selection: $selectedGroup) {
                Text("All Birds").tag(Optional<BirdGroup>.none)
                ForEach(appState.groups) { g in Text(g.name).tag(Optional<BirdGroup>.some(g)) }
            }
            .pickerStyle(.menu)
            .padding(10)
            .background(AdaptiveColor.card(scheme))
            .cornerRadius(10)
        }
    }

    @ViewBuilder private var datePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.compact).labelsHidden()
        }
    }

    private func saveRecord() {
        guard let n = Int(count), n >= 0 else { showError = true; return }
        let record = EggRecord(
            groupId: selectedGroup?.id ?? "all",
            groupName: selectedGroup?.name ?? "All Birds",
            count: n, date: date,
            brokenCount: Int(brokenCount) ?? 0, notes: notes
        )
        appState.addEggRecord(record)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Breeding View
struct BreedingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @State private var showAddPair = false
    @State private var showAddHatch = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Pairs").tag(0)
                Text("Hatch Records").tag(1)
                Text("Chicks").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(16)

            ScrollView {
                VStack(spacing: 12) {
                    if selectedTab == 0 {
                        if appState.breedingPairs.isEmpty {
                            EmptyStateView(icon: "💞", title: "No Breeding Pairs", message: "Set up breeding pairs to track your breeding program",
                                           action: { showAddPair = true }, actionLabel: "Add Pair")
                        } else {
                            ForEach(appState.breedingPairs) { pair in
                                BreedingPairRow(pair: pair)
                            }
                        }
                    } else if selectedTab == 1 {
                        if appState.hatchRecords.isEmpty {
                            EmptyStateView(icon: "🐣", title: "No Hatch Records", message: "Record when eggs hatch to track your breeding outcomes",
                                           action: { showAddHatch = true }, actionLabel: "Add Record")
                        } else {
                            ForEach(appState.hatchRecords) { record in
                                HatchRecordRow(record: record)
                            }
                        }
                    } else {
                        let chicks = appState.myBirds.filter { $0.ageInMonths < 3 }
                        if chicks.isEmpty {
                            EmptyStateView(icon: "🐤", title: "No Young Birds", message: "Birds under 3 months will appear here")
                        } else {
                            ForEach(chicks) { bird in
                                BirdRow(bird: bird)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle("Breeding")
        .navigationBarItems(trailing: Button(action: {
            if selectedTab == 0 { showAddPair = true } else { showAddHatch = true }
        }) {
            Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(Color(hex: "#805AD5"))
        })
        .sheet(isPresented: $showAddPair) { AddBreedingPairView() }
        .sheet(isPresented: $showAddHatch) { AddHatchRecordView() }
    }
}

struct BreedingPairRow: View {
    @EnvironmentObject var appState: AppState
    let pair: BreedingPair
    @Environment(\.colorScheme) var scheme
    @State private var showDelete = false

    var body: some View {
        DBCard {
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Text("🐓").font(.system(size: 24))
                        Image(systemName: "heart.fill").foregroundColor(Color(hex: "#E53E3E")).font(.system(size: 14))
                        Text("🐔").font(.system(size: 24))
                    }
                    Spacer()
                    TagChip(text: pair.status.rawValue, color: pair.status == .active ? .dbGreen : Color(hex: "#805AD5"))
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(pair.maleBirdName) × \(pair.femaleBirdName)")
                            .font(DBFont.headline(14)).foregroundColor(AdaptiveColor.text(scheme))
                        Text("Since \(pair.startDate, style: .date)")
                            .font(DBFont.label(12)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                    }
                    Spacer()
                    HStack(spacing: 16) {
                        VStack {
                            Text("\(pair.eggsSet)").font(DBFont.headline(16)).foregroundColor(Color(hex: "#E8A020"))
                            Text("set").font(DBFont.label(10)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                        }
                        VStack {
                            Text("\(pair.eggsHatched)").font(DBFont.headline(16)).foregroundColor(.dbGreen)
                            Text("hatched").font(DBFont.label(10)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                        }
                    }
                }
            }
            .padding(14)
        }
        .contextMenu {
            Button(role: .destructive) { showDelete = true } label: { Label("Delete", systemImage: "trash") }
        }
        .dbConfirmDelete(isPresented: $showDelete, itemName: "Breeding Pair") {
            appState.deleteBreedingPair(pair)
        }
    }
}

struct HatchRecordRow: View {
    let record: HatchRecord
    @Environment(\.colorScheme) var scheme

    var body: some View {
        DBCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color(hex: "#805AD5").opacity(0.12)).frame(width: 44, height: 44)
                    Text("🐣").font(.system(size: 22))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.date, style: .date).font(DBFont.headline(14)).foregroundColor(AdaptiveColor.text(scheme))
                    Text("\(record.chicksHatched) hatched · \(record.chicksLost) lost")
                        .font(DBFont.caption(13)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                }
                Spacer()
            }
            .padding(14)
        }
    }
}

struct AddBreedingPairView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @Environment(\.colorScheme) var scheme
    @State private var maleName = ""
    @State private var femaleName = ""
    @State private var eggsSet = ""
    @State private var startDate = Date()
    @State private var expectedHatch = Date().addingTimeInterval(21 * 86400)
    @State private var notes = ""
    @State private var showError = false

    var maleBirds: [MyBird] { appState.myBirds.filter { $0.gender == .male } }
    var femaleBirds: [MyBird] { appState.myBirds.filter { $0.gender == .female } }
    @State private var selectedMale: MyBird? = nil
    @State private var selectedFemale: MyBird? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    FormSection(title: "Breeding Pair") {
                        maleBirdSection
                        femaleBirdSection
                        DBTextField(placeholder: "Eggs set (optional)", text: $eggsSet, icon: "circle.fill", keyboardType: .numberPad)
                        startDatePicker
                        hatchDatePicker
                    }
                    if showError { Text("Both bird names are required").foregroundColor(.red).font(DBFont.caption()) }
                    DBButton("Add Pair", icon: "heart.fill", action: savePair)
                }
                .padding(16)
            }
            .background(AdaptiveColor.background(scheme).ignoresSafeArea())
            .navigationTitle("Add Breeding Pair")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss.wrappedValue.dismiss() })
        }
    }

    @ViewBuilder private var maleBirdSection: some View {
        if maleBirds.isEmpty {
            DBTextField(placeholder: "Male bird name", text: $maleName, icon: "bird")
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Male bird").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
                Picker("Male", selection: $selectedMale) {
                    Text("Type name below").tag(Optional<MyBird>.none)
                    ForEach(maleBirds) { b in Text(b.name).tag(Optional<MyBird>.some(b)) }
                }
                .pickerStyle(.menu).padding(10).background(AdaptiveColor.card(scheme)).cornerRadius(10)
            }
            if selectedMale == nil {
                DBTextField(placeholder: "Or type male name", text: $maleName, icon: "bird")
            }
        }
    }

    @ViewBuilder private var femaleBirdSection: some View {
        if femaleBirds.isEmpty {
            DBTextField(placeholder: "Female bird name", text: $femaleName, icon: "bird")
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Female bird").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
                Picker("Female", selection: $selectedFemale) {
                    Text("Type name below").tag(Optional<MyBird>.none)
                    ForEach(femaleBirds) { b in Text(b.name).tag(Optional<MyBird>.some(b)) }
                }
                .pickerStyle(.menu).padding(10).background(AdaptiveColor.card(scheme)).cornerRadius(10)
            }
            if selectedFemale == nil {
                DBTextField(placeholder: "Or type female name", text: $femaleName, icon: "bird")
            }
        }
    }

    @ViewBuilder private var startDatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start Date").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
            DatePicker("", selection: $startDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.compact).labelsHidden()
        }
    }

    @ViewBuilder private var hatchDatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Expected Hatch Date (optional)").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
            DatePicker("", selection: $expectedHatch, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.compact).labelsHidden()
        }
    }

    private func savePair() {
        let mName = selectedMale?.name ?? maleName
        let fName = selectedFemale?.name ?? femaleName
        guard !mName.isEmpty, !fName.isEmpty else { showError = true; return }
        let pair = BreedingPair(
            maleBirdId: selectedMale?.id ?? UUID().uuidString, maleBirdName: mName,
            femaleBirdId: selectedFemale?.id ?? UUID().uuidString, femaleBirdName: fName,
            startDate: startDate, expectedHatchDate: expectedHatch,
            eggsSet: Int(eggsSet) ?? 0, status: .active
        )
        appState.addBreedingPair(pair)
        dismiss.wrappedValue.dismiss()
    }
}

struct AddHatchRecordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @Environment(\.colorScheme) var scheme
    @State private var date = Date()
    @State private var chicksHatched = ""
    @State private var chicksLost = ""
    @State private var notes = ""
    @State private var selectedPair: BreedingPair? = nil
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    FormSection(title: "Hatch Record") {
                        if !appState.breedingPairs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Breeding pair").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
                                Picker("Pair", selection: $selectedPair) {
                                    Text("None").tag(Optional<BreedingPair>.none)
                                    ForEach(appState.breedingPairs) { p in
                                        Text("\(p.maleBirdName) × \(p.femaleBirdName)").tag(Optional<BreedingPair>.some(p))
                                    }
                                }
                                .pickerStyle(.menu).padding(10).background(AdaptiveColor.card(scheme)).cornerRadius(10)
                            }
                        }
                        DBTextField(placeholder: "Chicks hatched *", text: $chicksHatched, icon: "bird.fill", keyboardType: .numberPad)
                        DBTextField(placeholder: "Chicks lost", text: $chicksLost, icon: "xmark.circle", keyboardType: .numberPad)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hatch Date").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
                            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.compact).labelsHidden()
                        }
                        DBTextField(placeholder: "Notes", text: $notes, icon: "note.text")
                    }
                    if showError { Text("Chicks hatched is required").foregroundColor(.red).font(DBFont.caption()) }
                    DBButton("Save Record", icon: "checkmark.circle.fill") {
                        guard let n = Int(chicksHatched) else { showError = true; return }
                        let record = HatchRecord(
                            pairId: selectedPair?.id ?? "unknown",
                            date: date, chicksHatched: n,
                            chicksLost: Int(chicksLost) ?? 0, notes: notes
                        )
                        appState.addHatchRecord(record)
                        dismiss.wrappedValue.dismiss()
                    }
                }
                .padding(16)
            }
            .background(AdaptiveColor.background(scheme).ignoresSafeArea())
            .navigationTitle("Add Hatch Record")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss.wrappedValue.dismiss() })
        }
    }
}

// MARK: - Feeding View
struct FeedingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @State private var showAdd = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StatCard(title: "Feed This Week", value: String(format: "%.1f kg", appState.feedUsageThisWeek),
                         icon: "bag.fill", color: Color(hex: "#7B4F2E"), subtitle: "Last 7 days")

                SectionHeader(title: "Feed Records", action: { showAdd = true })

                if appState.feedRecords.isEmpty {
                    EmptyStateView(icon: "🌾", title: "No Feed Records", message: "Track what you feed your birds",
                                   action: { showAdd = true }, actionLabel: "Add Record")
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(appState.feedRecords.sorted { $0.date > $1.date }) { record in
                            FeedRecordRow(record: record) { appState.deleteFeedRecord(record) }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle("Feeding")
        .navigationBarItems(trailing: Button(action: { showAdd = true }) {
            Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(Color(hex: "#7B4F2E"))
        })
        .sheet(isPresented: $showAdd) { AddFeedRecordView() }
    }
}

struct FeedRecordRow: View {
    let record: FeedRecord
    let onDelete: () -> Void
    @Environment(\.colorScheme) var scheme
    @State private var showDelete = false

    var body: some View {
        DBCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color(hex: "#7B4F2E").opacity(0.12)).frame(width: 44, height: 44)
                    Text("🌾").font(.system(size: 22))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.feedType.rawValue).font(DBFont.headline(14)).foregroundColor(AdaptiveColor.text(scheme))
                    Text(record.groupName + " · " + record.date.formatted(date: .abbreviated, time: .omitted))
                        .font(DBFont.label(12)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f", record.amount)).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(Color(hex: "#7B4F2E"))
                    Text(record.unit.rawValue).font(DBFont.label(11)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                }
                Button(action: { showDelete = true }) {
                    Image(systemName: "trash").font(.system(size: 14)).foregroundColor(.red.opacity(0.6))
                }
            }
            .padding(14)
        }
        .dbConfirmDelete(isPresented: $showDelete, itemName: "Feed Record", action: onDelete)
    }
}

struct AddFeedRecordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @Environment(\.colorScheme) var scheme
    @State private var feedType: FeedType = .layerPellets
    @State private var amount = ""
    @State private var unit: FeedRecord.WeightUnit = .kg
    @State private var date = Date()
    @State private var cost = ""
    @State private var notes = ""
    @State private var selectedGroup: BirdGroup? = nil
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    FormSection(title: "Feed Record") {
                        feedTypePicker
                        DBTextField(placeholder: "Amount *", text: $amount, icon: "scalemass", keyboardType: .decimalPad)
                        unitPicker
                        feedGroupPicker
                        DBTextField(placeholder: "Cost (optional)", text: $cost, icon: "dollarsign.circle", keyboardType: .decimalPad)
                        feedDatePicker
                    }
                    if showError { Text("Amount is required").foregroundColor(.red).font(DBFont.caption()) }
                    DBButton("Save Record", icon: "checkmark.circle.fill", action: saveFeedRecord)
                }
                .padding(16)
            }
            .background(AdaptiveColor.background(scheme).ignoresSafeArea())
            .navigationTitle("Add Feed Record")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss.wrappedValue.dismiss() })
        }
    }

    @ViewBuilder private var feedTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Feed type").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
            Picker("Feed Type", selection: $feedType) {
                ForEach(FeedType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.menu).padding(10).background(AdaptiveColor.card(scheme)).cornerRadius(10)
        }
    }

    @ViewBuilder private var unitPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
            Picker("Unit", selection: $unit) {
                ForEach(FeedRecord.WeightUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(SegmentedPickerStyle())
        }
    }

    @ViewBuilder private var feedGroupPicker: some View {
        if !appState.groups.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Group").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
                Picker("Group", selection: $selectedGroup) {
                    Text("All Birds").tag(Optional<BirdGroup>.none)
                    ForEach(appState.groups) { g in Text(g.name).tag(Optional<BirdGroup>.some(g)) }
                }.pickerStyle(.menu).padding(10).background(AdaptiveColor.card(scheme)).cornerRadius(10)
            }
        }
    }

    @ViewBuilder private var feedDatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.compact).labelsHidden()
        }
    }

    private func saveFeedRecord() {
        guard let a = Double(amount), a > 0 else { showError = true; return }
        let record = FeedRecord(groupId: selectedGroup?.id, groupName: selectedGroup?.name ?? "All Birds",
                                feedType: feedType, amount: a, unit: unit, date: date,
                                cost: Double(cost) ?? 0, notes: notes)
        appState.addFeedRecord(record)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Health View
struct HealthView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @State private var showAdd = false
    @State private var showOnlyActive = false

    var displayedRecords: [HealthRecord] {
        showOnlyActive ? appState.healthRecords.filter { !$0.isResolved } : appState.healthRecords
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Active Issues", value: "\(appState.activeHealthIssues)", icon: "cross.circle.fill", color: Color(hex: "#E53E3E"))
                    StatCard(title: "Resolved", value: "\(appState.healthRecords.filter { $0.isResolved }.count)", icon: "checkmark.circle.fill", color: .dbGreen)
                }

                Toggle("Show active only", isOn: $showOnlyActive)
                    .font(DBFont.body())
                    .padding(12)
                    .background(AdaptiveColor.card(scheme))
                    .cornerRadius(12)

                if displayedRecords.isEmpty {
                    EmptyStateView(icon: "❤️", title: "No Health Records", message: "Track health issues and treatments",
                                   action: { showAdd = true }, actionLabel: "Add Record")
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(displayedRecords.sorted { $0.date > $1.date }) { record in
                            HealthRecordRow(record: record)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle("Health")
        .navigationBarItems(trailing: Button(action: { showAdd = true }) {
            Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(Color(hex: "#E53E3E"))
        })
        .sheet(isPresented: $showAdd) { AddHealthRecordView() }
    }
}

struct HealthRecordRow: View {
    @EnvironmentObject var appState: AppState
    var record: HealthRecord
    @Environment(\.colorScheme) var scheme
    @State private var showDelete = false
    @State private var localRecord: HealthRecord

    init(record: HealthRecord) {
        self.record = record
        _localRecord = State(initialValue: record)
    }

    var body: some View {
        DBCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    TagChip(text: localRecord.issueType.rawValue, color: Color(hex: "#E53E3E"))
                    Spacer()
                    Text(localRecord.date, style: .date).font(DBFont.label(12)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                    if localRecord.isResolved {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.dbGreen).font(.system(size: 16))
                    }
                }
                Text(localRecord.birdName).font(DBFont.headline(14)).foregroundColor(AdaptiveColor.text(scheme))
                if !localRecord.description.isEmpty {
                    Text(localRecord.description).font(DBFont.caption(13)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                }
                if !localRecord.treatment.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "pills.fill").font(.system(size: 11)).foregroundColor(.dbGreen)
                        Text(localRecord.treatment).font(DBFont.label(12)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                    }
                }
                HStack {
                    if !localRecord.isResolved {
                        Button(action: {
                            localRecord.isResolved = true
                            localRecord.resolvedDate = Date()
                            appState.updateHealthRecord(localRecord)
                        }) {
                            Label("Mark Resolved", systemImage: "checkmark.circle")
                                .font(DBFont.label(12)).foregroundColor(.dbGreen)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color.dbGreen.opacity(0.1)).cornerRadius(8)
                        }
                    }
                    Spacer()
                    Button(action: { showDelete = true }) {
                        Image(systemName: "trash").font(.system(size: 14)).foregroundColor(.red.opacity(0.6))
                    }
                }
            }
            .padding(14)
        }
        .dbConfirmDelete(isPresented: $showDelete, itemName: "Health Record") {
            appState.deleteHealthRecord(record)
        }
    }
}

struct AddHealthRecordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @Environment(\.colorScheme) var scheme
    @State private var birdName = ""
    @State private var issueType: HealthIssueType = .checkup
    @State private var description = ""
    @State private var treatment = ""
    @State private var date = Date()
    @State private var cost = ""
    @State private var vetName = ""
    @State private var selectedBird: MyBird? = nil
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    FormSection(title: "Health Record") {
                        healthBirdPicker
                        healthIssueTypePicker
                        DBTextField(placeholder: "Description", text: $description, icon: "text.alignleft")
                        DBTextField(placeholder: "Treatment", text: $treatment, icon: "pills.fill")
                        DBTextField(placeholder: "Vet name (optional)", text: $vetName, icon: "person.fill")
                        DBTextField(placeholder: "Cost (optional)", text: $cost, icon: "dollarsign.circle", keyboardType: .decimalPad)
                        healthDatePicker
                    }
                    if showError { Text("Bird name is required").foregroundColor(.red).font(DBFont.caption()) }
                    DBButton("Save Record", icon: "checkmark.circle.fill", action: saveHealthRecord)
                }
                .padding(16)
            }
            .background(AdaptiveColor.background(scheme).ignoresSafeArea())
            .navigationTitle("Add Health Record")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss.wrappedValue.dismiss() })
        }
    }

    @ViewBuilder private var healthBirdPicker: some View {
        if !appState.myBirds.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bird").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
                Picker("Bird", selection: $selectedBird) {
                    Text("Type name below").tag(Optional<MyBird>.none)
                    ForEach(appState.myBirds) { b in Text(b.name).tag(Optional<MyBird>.some(b)) }
                }.pickerStyle(.menu).padding(10).background(AdaptiveColor.card(scheme)).cornerRadius(10)
            }
        }
        if selectedBird == nil {
            DBTextField(placeholder: "Bird name *", text: $birdName, icon: "bird")
        }
    }

    @ViewBuilder private var healthIssueTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Issue type").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
            Picker("Issue", selection: $issueType) {
                ForEach(HealthIssueType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.menu).padding(10).background(AdaptiveColor.card(scheme)).cornerRadius(10)
        }
    }

    @ViewBuilder private var healthDatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.compact).labelsHidden()
        }
    }

    private func saveHealthRecord() {
        let name = selectedBird?.name ?? birdName
        guard !name.isEmpty else { showError = true; return }
        let record = HealthRecord(birdId: selectedBird?.id, birdName: name, issueType: issueType,
                                  description: description, treatment: treatment, date: date,
                                  cost: Double(cost) ?? 0, vetName: vetName)
        appState.addHealthRecord(record)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Housing View
struct HousingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @State private var showAdd = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if appState.coops.isEmpty {
                    EmptyStateView(icon: "🏠", title: "No Coops", message: "Add your coops and enclosures",
                                   action: { showAdd = true }, actionLabel: "Add Coop")
                } else {
                    ForEach(appState.coops) { coop in
                        CoopRow(coop: coop)
                    }
                }
            }
            .padding(16)
        }
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle("Housing")
        .navigationBarItems(trailing: Button(action: { showAdd = true }) {
            Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(Color(hex: "#3A9BD5"))
        })
        .sheet(isPresented: $showAdd) { AddCoopView() }
    }
}

struct CoopRow: View {
    @EnvironmentObject var appState: AppState
    let coop: Coop
    @Environment(\.colorScheme) var scheme
    @State private var showDelete = false

    var body: some View {
        DBCard {
            VStack(spacing: 12) {
                HStack {
                    ZStack {
                        Circle().fill(Color(hex: "#3A9BD5").opacity(0.12)).frame(width: 48, height: 48)
                        Image(systemName: "house.fill").font(.system(size: 20)).foregroundColor(Color(hex: "#3A9BD5"))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(coop.name).font(DBFont.headline(15)).foregroundColor(AdaptiveColor.text(scheme))
                        Text("Capacity: \(coop.currentOccupancy)/\(coop.capacity)")
                            .font(DBFont.caption(13)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                    }
                    Spacer()
                    Button(action: { showDelete = true }) {
                        Image(systemName: "trash").foregroundColor(.red.opacity(0.6))
                    }
                }
                // Occupancy bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(AdaptiveColor.border(scheme)).frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(coop.occupancyPercentage > 0.8 ? Color.red : Color(hex: "#3A9BD5"))
                            .frame(width: geo.size.width * CGFloat(min(coop.occupancyPercentage, 1.0)), height: 8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: coop.occupancyPercentage)
                    }
                }
                .frame(height: 8)
                if !coop.description.isEmpty {
                    Text(coop.description).font(DBFont.caption(13)).foregroundColor(AdaptiveColor.textSecondary(scheme)).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(14)
        }
        .dbConfirmDelete(isPresented: $showDelete, itemName: coop.name) { appState.deleteCoop(coop) }
    }
}

struct DomesticBirdsWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "db_target") ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}
struct AddCoopView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @Environment(\.colorScheme) var scheme
    @State private var name = ""
    @State private var capacity = ""
    @State private var occupancy = ""
    @State private var description = ""
    @State private var features = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    FormSection(title: "Coop Details") {
                        DBTextField(placeholder: "Coop name *", text: $name, icon: "house")
                        DBTextField(placeholder: "Maximum capacity *", text: $capacity, icon: "person.3", keyboardType: .numberPad)
                        DBTextField(placeholder: "Current occupancy", text: $occupancy, icon: "bird", keyboardType: .numberPad)
                        DBTextField(placeholder: "Description (optional)", text: $description, icon: "text.alignleft")
                        DBTextField(placeholder: "Features (e.g. heated, insulated)", text: $features, icon: "star")
                    }
                    if showError { Text("Coop name and capacity are required").foregroundColor(.red).font(DBFont.caption()) }
                    DBButton("Add Coop", icon: "house.fill") {
                        guard !name.isEmpty, let cap = Int(capacity) else { showError = true; return }
                        let featureList = features.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        let coop = Coop(name: name, capacity: cap, currentOccupancy: Int(occupancy) ?? 0,
                                        description: description, features: featureList)
                        appState.addCoop(coop)
                        dismiss.wrappedValue.dismiss()
                    }
                }
                .padding(16)
            }
            .background(AdaptiveColor.background(scheme).ignoresSafeArea())
            .navigationTitle("Add Coop")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss.wrappedValue.dismiss() })
        }
    }
}

// MARK: - Reports View
struct ReportsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    var totalEggsAllTime: Int { appState.eggRecords.reduce(0) { $0 + $1.count } }
    var totalFeedCost: Double { appState.feedRecords.reduce(0) { $0 + $1.cost } }
    var totalHealthCost: Double { appState.healthRecords.reduce(0) { $0 + $1.cost } }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary
                DBCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Farm Overview").font(DBFont.headline()).foregroundColor(AdaptiveColor.text(scheme))
                        Divider()
                        ReportRow(label: "Total Birds", value: "\(appState.myBirds.count)", color: .dbGreen)
                        ReportRow(label: "Active Groups", value: "\(appState.groups.count)", color: Color(hex: "#52A865"))
                        ReportRow(label: "Total Eggs Recorded", value: "\(totalEggsAllTime)", color: Color(hex: "#E8A020"))
                        ReportRow(label: "Breeding Pairs", value: "\(appState.breedingPairs.count)", color: Color(hex: "#805AD5"))
                        ReportRow(label: "Feed Records", value: "\(appState.feedRecords.count)", color: Color(hex: "#7B4F2E"))
                        ReportRow(label: "Health Records", value: "\(appState.healthRecords.count)", color: Color(hex: "#E53E3E"))
                        ReportRow(label: "Coops", value: "\(appState.coops.count)", color: Color(hex: "#3A9BD5"))
                    }
                    .padding(16)
                }

                // Costs
                if totalFeedCost > 0 || totalHealthCost > 0 {
                    DBCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Cost Summary").font(DBFont.headline()).foregroundColor(AdaptiveColor.text(scheme))
                            Divider()
                            ReportRow(label: "Feed Cost (total)", value: String(format: "$%.2f", totalFeedCost), color: Color(hex: "#7B4F2E"))
                            ReportRow(label: "Health Cost (total)", value: String(format: "$%.2f", totalHealthCost), color: Color(hex: "#E53E3E"))
                            Divider()
                            ReportRow(label: "Total Spending", value: String(format: "$%.2f", totalFeedCost + totalHealthCost), color: .dbGreen)
                        }
                        .padding(16)
                    }
                }

                // Egg chart
                if !appState.eggRecords.isEmpty {
                    DBCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Egg Production Trend (7 days)").font(DBFont.headline()).foregroundColor(AdaptiveColor.text(scheme))
                            SparklineChart(values: appState.eggsForLast7Days(), color: Color(hex: "#E8A020"))
                                .frame(height: 100)
                            HStack {
                                Text("Avg: \(appState.totalEggsThisWeek / 7) eggs/day")
                                    .font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
                                Spacer()
                                Text("Total: \(appState.totalEggsThisWeek) this week")
                                    .font(DBFont.label()).foregroundColor(.dbGreen)
                            }
                        }
                        .padding(16)
                    }
                }

                // Bird health summary
                DBCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Flock Health").font(DBFont.headline()).foregroundColor(AdaptiveColor.text(scheme))
                        Divider()
                        ForEach(BirdHealthStatus.allCases, id: \.self) { status in
                            let count = appState.myBirds.filter { $0.healthStatus == status }.count
                            if count > 0 {
                                HStack {
                                    Circle().fill(status.color).frame(width: 8, height: 8)
                                    Text(status.rawValue).font(DBFont.body(14)).foregroundColor(AdaptiveColor.text(scheme))
                                    Spacer()
                                    Text("\(count) bird\(count != 1 ? "s" : "")").font(DBFont.headline(14)).foregroundColor(status.color)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .padding(16)
        }
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle("Reports")
    }
}

struct ReportRow: View {
    let label: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(DBFont.body(14)).foregroundColor(AdaptiveColor.textSecondary(scheme))
            Spacer()
            Text(value).font(DBFont.headline(14)).foregroundColor(color)
        }
    }
}

// MARK: - Activity History
struct ActivityHistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    var body: some View {
        List {
            if appState.activityLog.isEmpty {
                EmptyStateView(icon: "📋", title: "No Activity", message: "Actions you take will appear here")
                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
            } else {
                ForEach(appState.activityLog) { log in
                    ActivityRow(log: log)
                        .listRowBackground(AdaptiveColor.card(scheme))
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
        }
        .listStyle(.plain)
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle("Activity Log")
    }
}
