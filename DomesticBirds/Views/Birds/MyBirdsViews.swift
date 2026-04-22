import SwiftUI

// MARK: - My Birds Navigation
struct MyBirdsNavigationView: View {
    var body: some View {
        NavigationView {
            MyBirdsView()
        }
    }
}

struct MyBirdsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @State private var showAddBird = false
    @State private var searchText = ""
    @State private var filterCategory: BirdCategory? = nil
    @State private var filterHealth: BirdHealthStatus? = nil
    @State private var birdToDelete: MyBird? = nil
    @State private var showDeleteConfirm = false

    var filteredBirds: [MyBird] {
        var birds = appState.myBirds
        if let cat = filterCategory { birds = birds.filter { $0.type == cat } }
        if let h = filterHealth { birds = birds.filter { $0.healthStatus == h } }
        if !searchText.isEmpty {
            birds = birds.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.breed.localizedCaseInsensitiveContains(searchText)
            }
        }
        return birds
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(.dbTextTert)
                TextField("Search birds...", text: $searchText).font(DBFont.body())
            }
            .padding(12)
            .background(AdaptiveColor.card(scheme))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AdaptiveColor.border(scheme), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)

            // Filter bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All", isSelected: filterCategory == nil) { filterCategory = nil }
                    ForEach(BirdCategory.allCases, id: \.self) { cat in
                        FilterChip(label: cat.icon + " " + cat.rawValue, isSelected: filterCategory == cat) {
                            filterCategory = filterCategory == cat ? nil : cat
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)

            if filteredBirds.isEmpty {
                EmptyStateView(
                    icon: "🐔",
                    title: "No Birds Yet",
                    message: "Add your first bird to start tracking your flock",
                    action: { showAddBird = true },
                    actionLabel: "Add Bird"
                )
                .padding(.top, 40)
                Spacer()
            } else {
                List {
                    ForEach(filteredBirds) { bird in
                        NavigationLink(destination: BirdDetailView(bird: bird)) {
                            BirdRow(bird: bird)
                        }
                        .listRowBackground(AdaptiveColor.card(scheme))
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                birdToDelete = bird
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .background(AdaptiveColor.background(scheme))
            }
        }
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle("My Birds")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarItems(trailing: Button(action: { showAddBird = true }) {
            Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.dbGreen)
        })
        .sheet(isPresented: $showAddBird) { AddBirdView() }
        .alert("Delete Bird?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let b = birdToDelete { appState.deleteBird(b) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove \(birdToDelete?.name ?? "this bird") from your flock.")
        }
    }
}

struct BirdRow: View {
    let bird: MyBird
    @Environment(\.colorScheme) var scheme

    var body: some View {
        DBCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(bird.type.color.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Text(bird.type.icon).font(.system(size: 26))
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(bird.name).font(DBFont.headline(15)).foregroundColor(AdaptiveColor.text(scheme))
                        Spacer()
                        HealthBadge(status: bird.healthStatus)
                    }
                    Text(bird.breed).font(DBFont.caption(13)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                    HStack(spacing: 8) {
                        TagChip(text: bird.gender.rawValue, color: Color(hex: "#3A9BD5"))
                        Text(bird.ageDisplay).font(DBFont.label(11)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                    }
                }
            }
            .padding(14)
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DBFont.label(12))
                .foregroundColor(isSelected ? .white : .dbText)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.dbGreen : Color.dbGreenPale.opacity(0.6))
                .cornerRadius(16)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Add Bird
struct AddBirdView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @Environment(\.colorScheme) var scheme

    @State private var name = ""
    @State private var selectedType: BirdCategory = .chickens
    @State private var breed = ""
    @State private var gender: BirdGender = .female
    @State private var birthDate = Date()
    @State private var tagNumber = ""
    @State private var weight = ""
    @State private var notes = ""
    @State private var selectedGroup: BirdGroup? = nil
    @State private var selectedCoop: Coop? = nil
    @State private var showError = false
    @State private var errorMsg = ""

    // Breed suggestions based on type
    var breedSuggestions: [String] {
        BirdBreed.catalog.filter { $0.category == selectedType }.map { $0.name }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    // Bird type picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bird Type").font(DBFont.headline(14)).foregroundColor(AdaptiveColor.text(scheme))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(BirdCategory.allCases, id: \.self) { cat in
                                    Button(action: { selectedType = cat; breed = "" }) {
                                        VStack(spacing: 4) {
                                            Text(cat.icon).font(.system(size: 26))
                                            Text(cat.rawValue).font(DBFont.label(11))
                                                .foregroundColor(selectedType == cat ? .white : AdaptiveColor.text(scheme))
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(selectedType == cat ? cat.color : AdaptiveColor.card(scheme))
                                        .cornerRadius(14)
                                    }
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedType)
                                }
                            }
                        }
                    }

                    FormSection(title: "Basic Info") {
                        DBTextField(placeholder: "Bird name *", text: $name, icon: "bird")
                        // Breed with suggestions
                        VStack(alignment: .leading, spacing: 6) {
                            DBTextField(placeholder: "Breed *", text: $breed, icon: "pawprint")
                            if !breed.isEmpty {
                                let matches = breedSuggestions.filter { $0.localizedCaseInsensitiveContains(breed) }.prefix(3)
                                if !matches.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(Array(matches), id: \.self) { s in
                                                Button(action: { breed = s }) {
                                                    Text(s).font(DBFont.caption(12))
                                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                                        .background(Color.dbGreen.opacity(0.12))
                                                        .foregroundColor(.dbGreen)
                                                        .cornerRadius(8)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        DBTextField(placeholder: "Tag / Ring number", text: $tagNumber, icon: "tag")
                        DBTextField(placeholder: "Weight (kg)", text: $weight, icon: "scalemass", keyboardType: .decimalPad)
                    }

//                    FormSection(title: "Details") {
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Gender").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
//                            Picker("Gender", selection: $gender) {
//                                ForEach(BirdGender.allCases, id: \.self) { g in
//                                    Text(g.rawValue).tag(g)
//                                }
//                            }
//                            .pickerStyle(SegmentedPickerStyle())
//                        }
//
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Date of Birth").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
//                            DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
//                                .datePickerStyle(.compact)
//                                .labelsHidden()
//                        }
//
//                        if !appState.groups.isEmpty {
//                            VStack(alignment: .leading, spacing: 8) {
//                                Text("Group (optional)").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
//                                Picker("Group", selection: $selectedGroup) {
//                                    Text("None").tag(Optional<BirdGroup>.none)
//                                    ForEach(appState.groups) { g in
//                                        Text(g.name).tag(Optional<BirdGroup>.some(g))
//                                    }
//                                }
//                                .pickerStyle(.menu)
//                                .padding(10)
//                                .background(AdaptiveColor.card(scheme))
//                                .cornerRadius(10)
//                            }
//                        }
//
//                        if !appState.coops.isEmpty {
//                            VStack(alignment: .leading, spacing: 8) {
//                                Text("Coop (optional)").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
//                                Picker("Coop", selection: $selectedCoop) {
//                                    Text("None").tag(Optional<Coop>.none)
//                                    ForEach(appState.coops) { c in
//                                        Text(c.name).tag(Optional<Coop>.some(c))
//                                    }
//                                }
//                                .pickerStyle(.menu)
//                                .padding(10)
//                                .background(AdaptiveColor.card(scheme))
//                                .cornerRadius(10)
//                            }
//                        }
//                    }

                    FormSection(title: "Notes") {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $notes)
                                .frame(minHeight: 80)
                                .font(DBFont.body())
                                .padding(8)
                                .background(AdaptiveColor.card(scheme))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AdaptiveColor.border(scheme), lineWidth: 1.5))
                            if notes.isEmpty {
                                Text("Any notes about this bird...").font(DBFont.body()).foregroundColor(.dbTextTert).padding(14)
                                    .allowsHitTesting(false)
                            }
                        }
                    }

                    if showError {
                        Text(errorMsg).font(DBFont.caption()).foregroundColor(Color(hex: "#E53E3E"))
                            .padding(10).background(Color(hex: "#E53E3E").opacity(0.1)).cornerRadius(8)
                    }

                    DBButton("Add Bird", icon: "plus.circle.fill") { saveBird() }
                    Spacer(minLength: 30)
                }
                .padding(16)
            }
            .background(AdaptiveColor.background(scheme).ignoresSafeArea())
            .navigationTitle("Add Bird")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss.wrappedValue.dismiss() })
        }
    }

    private func saveBird() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError = true; errorMsg = "Bird name is required"; return
        }
        guard !breed.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError = true; errorMsg = "Breed is required"; return
        }
        let bird = MyBird(
            name: name.trimmingCharacters(in: .whitespaces),
            type: selectedType,
            breed: breed,
            gender: gender,
            birthDate: birthDate,
            groupId: selectedGroup?.id,
            coopId: selectedCoop?.id,
            weight: Double(weight) ?? 0,
            notes: notes,
            tagNumber: tagNumber
        )
        appState.addBird(bird)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Bird Detail
struct BirdDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @State var bird: MyBird
    @State private var showEdit = false

    var eggHistory: [EggRecord] {
        if let gid = bird.groupId {
            return appState.eggRecords.filter { $0.groupId == gid }.prefix(7).map { $0 }
        }
        return []
    }

    var healthHistory: [HealthRecord] {
        appState.healthRecords.filter { $0.birdId == bird.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Hero
                ZStack {
                    LinearGradient(colors: [bird.type.color, bird.type.color.opacity(0.7)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 180)
                        .cornerRadius(20)

                    HStack(spacing: 20) {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.15)).frame(width: 80, height: 80)
                            Text(bird.type.icon).font(.system(size: 44))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(bird.name).font(.system(size: 26, weight: .bold, design: .rounded)).foregroundColor(.white)
                            Text(bird.breed).font(DBFont.body()).foregroundColor(.white.opacity(0.85))
                            HStack(spacing: 8) {
                                TagChip(text: bird.gender.rawValue, color: .white)
                                    .background(Color.white.opacity(0.2))
                                HealthBadge(status: bird.healthStatus)
                            }
                        }
                        Spacer()
                    }
                    .padding(20)
                }

                // Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    BirdStatBubble(label: "Age", value: bird.ageDisplay, icon: "clock.fill")
                    BirdStatBubble(label: "Weight", value: bird.weight > 0 ? "\(bird.weight)kg" : "—", icon: "scalemass.fill")
                    BirdStatBubble(label: "Tag", value: bird.tagNumber.isEmpty ? "—" : bird.tagNumber, icon: "tag.fill")
                }

                // Group info
                if let gid = bird.groupId, let group = appState.groups.first(where: { $0.id == gid }) {
                    DBCard {
                        HStack {
                            Image(systemName: "person.3.fill").foregroundColor(group.purpose.color)
                            Text("Group: \(group.name)").font(DBFont.headline(14)).foregroundColor(AdaptiveColor.text(scheme))
                            Spacer()
                            TagChip(text: group.purpose.rawValue, color: group.purpose.color)
                        }
                        .padding(14)
                    }
                }

                // Health history
                if !healthHistory.isEmpty {
                    DBCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Health History", systemImage: "cross.circle.fill").font(DBFont.headline(14)).foregroundColor(Color(hex: "#E53E3E"))
                            ForEach(healthHistory.prefix(3)) { record in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(record.issueType.rawValue).font(DBFont.caption(13)).foregroundColor(AdaptiveColor.text(scheme))
                                        Text(record.treatment.isEmpty ? "No treatment noted" : record.treatment)
                                            .font(DBFont.label(11)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                                    }
                                    Spacer()
                                    Text(record.date, style: .date).font(DBFont.label(11)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                                }
                            }
                        }
                        .padding(14)
                    }
                }

                // Notes
                if !bird.notes.isEmpty {
                    DBCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Notes", systemImage: "note.text").font(DBFont.headline(14)).foregroundColor(.dbGreen)
                            Text(bird.notes).font(DBFont.body(14)).foregroundColor(AdaptiveColor.textSecondary(scheme))
                        }
                        .padding(14)
                    }
                }
            }
            .padding(16)
        }
        .background(AdaptiveColor.background(scheme).ignoresSafeArea())
        .navigationTitle(bird.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Edit") { showEdit = true })
        .sheet(isPresented: $showEdit) { EditBirdView(bird: $bird) }
    }
}

struct DomesticBirdsNotificationView: View {
    
    let viewModel: DomesticBirdsViewModel
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.custom("MadimiOne-Regular", size: 24))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "notification_bg2" : "notification_bg")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.requestPermission()
            } label: {
                Image("notification_btn")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                viewModel.deferPermission()
            } label: {
                Image("notification_btn2")
                    .resizable()
                    .frame(width: 280, height: 35)
            }
        }
        .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.custom("MadimiOne-Regular", size: 16))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
}


struct BirdStatBubble: View {
    let label: String
    let value: String
    let icon: String
    @Environment(\.colorScheme) var scheme

    var body: some View {
        DBCard {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(.dbGreen)
                Text(value).font(DBFont.headline(13)).foregroundColor(AdaptiveColor.text(scheme)).lineLimit(1)
                Text(label).font(DBFont.label(10)).foregroundColor(AdaptiveColor.textSecondary(scheme))
            }
            .padding(12)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Edit Bird
struct EditBirdView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var dismiss
    @Environment(\.colorScheme) var scheme
    @Binding var bird: MyBird

    @State private var name: String
    @State private var breed: String
    @State private var gender: BirdGender
    @State private var birthDate: Date
    @State private var weight: String
    @State private var notes: String
    @State private var healthStatus: BirdHealthStatus
    @State private var tagNumber: String

    init(bird: Binding<MyBird>) {
        _bird = bird
        _name = State(initialValue: bird.wrappedValue.name)
        _breed = State(initialValue: bird.wrappedValue.breed)
        _gender = State(initialValue: bird.wrappedValue.gender)
        _birthDate = State(initialValue: bird.wrappedValue.birthDate)
        _weight = State(initialValue: bird.wrappedValue.weight > 0 ? "\(bird.wrappedValue.weight)" : "")
        _notes = State(initialValue: bird.wrappedValue.notes)
        _healthStatus = State(initialValue: bird.wrappedValue.healthStatus)
        _tagNumber = State(initialValue: bird.wrappedValue.tagNumber)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    FormSection(title: "Basic Info") {
                        DBTextField(placeholder: "Bird name", text: $name, icon: "bird")
                        DBTextField(placeholder: "Breed", text: $breed, icon: "pawprint")
                        DBTextField(placeholder: "Tag / Ring number", text: $tagNumber, icon: "tag")
                        DBTextField(placeholder: "Weight (kg)", text: $weight, icon: "scalemass", keyboardType: .decimalPad)
                    }
                    FormSection(title: "Status") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
                            Picker("Gender", selection: $gender) {
                                ForEach(BirdGender.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }.pickerStyle(SegmentedPickerStyle())
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Health Status").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
                            Picker("Health", selection: $healthStatus) {
                                ForEach(BirdHealthStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }.pickerStyle(SegmentedPickerStyle())
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date of Birth").font(DBFont.caption()).foregroundColor(AdaptiveColor.textSecondary(scheme))
                            DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.compact).labelsHidden()
                        }
                    }
                    FormSection(title: "Notes") {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $notes).frame(minHeight: 80).font(DBFont.body()).padding(8)
                                .background(AdaptiveColor.card(scheme)).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AdaptiveColor.border(scheme), lineWidth: 1.5))
                            if notes.isEmpty {
                                Text("Notes...").font(DBFont.body()).foregroundColor(.dbTextTert).padding(14).allowsHitTesting(false)
                            }
                        }
                    }
                    DBButton("Save Changes", icon: "checkmark.circle.fill") { saveChanges() }
                }
                .padding(16)
            }
            .background(AdaptiveColor.background(scheme).ignoresSafeArea())
            .navigationTitle("Edit Bird")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss.wrappedValue.dismiss() })
        }
    }

    private func saveChanges() {
        bird.name = name
        bird.breed = breed
        bird.gender = gender
        bird.birthDate = birthDate
        bird.weight = Double(weight) ?? bird.weight
        bird.notes = notes
        bird.healthStatus = healthStatus
        bird.tagNumber = tagNumber
        appState.updateBird(bird)
        dismiss.wrappedValue.dismiss()
    }
}

// MARK: - Form Section Helper
struct FormSection<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.colorScheme) var scheme

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(DBFont.headline(14)).foregroundColor(AdaptiveColor.text(scheme))
            VStack(spacing: 10) { content }
                .padding(14)
                .background(AdaptiveColor.card(scheme))
                .cornerRadius(14)
        }
    }
}
