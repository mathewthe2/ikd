import SwiftUI

struct SearchResult: Identifiable {

    let id = UUID()

    let title: String
    let subtitle: String
    let icon: String
}

struct ContentView: View {

    let onResultsChanged: (Bool) -> Void

    @State private var query = ""

    @FocusState private var searchFieldFocused: Bool

    private let results = [

        SearchResult(
            title: "Apple",
            subtitle: "Technology company",
            icon: "apple.logo"
        ),

        SearchResult(
            title: "Swift",
            subtitle: "Programming language",
            icon: "swift"
        ),

        SearchResult(
            title: "Xcode",
            subtitle: "Apple development environment",
            icon: "hammer"
        ),

        SearchResult(
            title: "Safari",
            subtitle: "Web browser",
            icon: "safari"
        )
    ]

    private var filteredResults: [SearchResult] {

        if query.isEmpty {
            return []
        }

        return results.filter {

            $0.title.localizedCaseInsensitiveContains(query)
            ||
            $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - Search Bar

            HStack(spacing: 14) {

                Image(
                    systemName: "magnifyingglass"
                )
                .font(
                    .system(
                        size: 21,
                        weight: .medium
                    )
                )
                .foregroundStyle(.secondary)

                TextField(
                    "Search",
                    text: $query
                )
                .textFieldStyle(.plain)
                .font(.system(size: 21))
                .focused(
                    $searchFieldFocused
                )

                if !query.isEmpty {

                    Button {

                        query = ""

                    } label: {

                        Image(
                            systemName:
                                "xmark.circle.fill"
                        )
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 22)
            .frame(height: 64)

            // MARK: - Results

            if !filteredResults.isEmpty {

                Divider()
                    .opacity(0.4)

                ScrollView {

                    VStack(spacing: 2) {

                        ForEach(
                            filteredResults
                        ) { result in

                            SearchResultRow(
                                result: result
                            )
                        }
                    }
                    .padding(10)
                }
            }
        }

        // Keep search bar pinned to the top.
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )

        // MARK: - Background

        .background(
            RoundedRectangle(
                cornerRadius: 18
            )
            .fill(.regularMaterial)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 18
            )
            .stroke(
                Color.white.opacity(0.12),
                lineWidth: 1
            )
        )
        .shadow(
            color: .black.opacity(0.25),
            radius: 30,
            y: 10
        )

        // MARK: - Results Changed

        .onChange(of: filteredResults.count) {

            onResultsChanged(
                !filteredResults.isEmpty
            )
        }

        // MARK: - App Became Active

        .onReceive(
            NotificationCenter.default.publisher(
                for: NSApplication.didBecomeActiveNotification
            )
        ) { _ in

            // Restore focus to the search field.
            searchFieldFocused = true

            // Recalculate the window state.
            //
            // This is important if there was a query
            // before the window was hidden.
            onResultsChanged(
                !filteredResults.isEmpty
            )
        }

        .onAppear {

            searchFieldFocused = true

            onResultsChanged(
                !filteredResults.isEmpty
            )
        }
    }
}

struct SearchResultRow: View {

    let result: SearchResult

    var body: some View {

        HStack(spacing: 14) {

            Image(
                systemName: result.icon
            )
            .font(.system(size: 22))
            .frame(
                width: 42,
                height: 42
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 9
                )
                .fill(
                    Color.secondary.opacity(0.12)
                )
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(result.title)
                    .font(
                        .system(
                            size: 15,
                            weight: .medium
                        )
                    )

                Text(result.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(
            .horizontal,
            10
        )
        .padding(
            .vertical,
            8
        )
    }
}
