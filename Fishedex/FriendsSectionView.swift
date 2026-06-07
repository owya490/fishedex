import SwiftUI

struct FriendsSectionView: View {
    @EnvironmentObject private var session: SessionManager

    @Binding var selectedFriendId: UUID?

    @State private var emailQuery = ""
    @State private var searchResult: ProfileRow?
    @State private var isSearching = false
    @State private var isAdding = false
    @State private var acceptingRequestID: UUID?
    @State private var decliningRequestID: UUID?
    @State private var friendsMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            friendsHeader

            HStack(spacing: 8) {
                TextField("Friend's email", text: $emailQuery)
                    .font(FishedexFont.body)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)

                Button {
                    Task { await searchFriend() }
                } label: {
                    Group {
                        if isSearching {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("FIND")
                                .font(FishedexFont.caption)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 40)
                    .background(FishedexTheme.ocean)
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)
                }
                .buttonStyle(.plain)
                .disabled(isSearching || emailQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let friendsMessage {
                Text(friendsMessage.uppercased())
                    .font(FishedexFont.micro)
                    .foregroundStyle(FishedexTheme.muted)
            }

            if let searchResult {
                searchResultCard(searchResult)
            }

            if !session.incomingFriendRequests.isEmpty {
                incomingRequestsSection
            }

            if !session.outgoingPendingFriends.isEmpty {
                pendingOutgoingSection
            }

            if session.friends.isEmpty && session.incomingFriendRequests.isEmpty && session.outgoingPendingFriends.isEmpty {
                Text("No friends yet. Search by email to send a request.")
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.muted)
                    .padding(.vertical, 8)
            } else if !session.friends.isEmpty {
                acceptedFriendsSection
            }
        }
        .padding(18)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder()
    }

    private var friendsHeader: some View {
        HStack {
            Text("FRIENDS")
                .font(FishedexFont.headline)
                .foregroundStyle(FishedexTheme.ink)

            Spacer()

            if !session.incomingFriendRequests.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(session.incomingFriendRequests.count)")
                        .font(FishedexFont.micro)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(FishedexTheme.headerRed)
                .fishedexSquare()
            }
        }
    }

    private var incomingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FRIEND REQUESTS")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.headerRed)

            ForEach(session.incomingFriendRequests) { request in
                incomingRequestRow(request)
            }
        }
    }

    private var pendingOutgoingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PENDING")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)

            ForEach(session.outgoingPendingFriends) { pending in
                pendingOutgoingRow(pending)
            }
        }
    }

    private var acceptedFriendsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR FRIENDS")
                .font(FishedexFont.caption)
                .foregroundStyle(FishedexTheme.muted)

            ForEach(session.friends) { friend in
                Button {
                    selectedFriendId = friend.profile.id
                } label: {
                    friendRow(friend.profile, statusTag: nil)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func incomingRequestRow(_ request: FriendRequest) -> some View {
        HStack(spacing: 12) {
            ProfileAvatarView(urlString: request.requester.avatarUrl, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text((request.requester.displayName ?? "ANGLER").uppercased())
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.ink)
                Text("WANTS TO BE FRIENDS")
                    .font(FishedexFont.micro)
                    .foregroundStyle(FishedexTheme.headerRed)
            }

            Spacer()

            HStack(spacing: 6) {
                Button {
                    Task { await declineRequest(request) }
                } label: {
                    Group {
                        if decliningRequestID == request.friendshipId {
                            ProgressView()
                                .tint(FishedexTheme.muted)
                        } else {
                            Text("DECLINE")
                                .font(FishedexFont.micro)
                        }
                    }
                    .foregroundStyle(FishedexTheme.muted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)
                }
                .buttonStyle(.plain)
                .disabled(decliningRequestID == request.friendshipId || acceptingRequestID == request.friendshipId)

                Button {
                    Task { await acceptRequest(request) }
                } label: {
                    Group {
                        if acceptingRequestID == request.friendshipId {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("ACCEPT")
                                .font(FishedexFont.caption)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(FishedexTheme.tabGreen)
                    .fishedexSquare()
                    .fishedexBorder(lineWidth: 1)
                }
                .buttonStyle(.plain)
                .disabled(decliningRequestID == request.friendshipId || acceptingRequestID == request.friendshipId)
            }
        }
        .padding(10)
        .background(FishedexTheme.cream.opacity(0.55))
        .fishedexSquare()
        .fishedexBorder(lineWidth: 1, color: FishedexTheme.headerRed.opacity(0.35))
    }

    private func pendingOutgoingRow(_ pending: FriendSummary) -> some View {
        friendRow(pending.profile, statusTag: "PENDING")
    }

    private func searchResultCard(_ profile: ProfileRow) -> some View {
        HStack(spacing: 12) {
            ProfileAvatarView(urlString: profile.avatarUrl, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text((profile.displayName ?? "ANGLER").uppercased())
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.ink)
                Text("LV. \(profile.level)")
                    .font(FishedexFont.micro)
                    .foregroundStyle(FishedexTheme.muted)
            }

            Spacer()

            searchResultAction(for: profile)
        }
        .padding(10)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder(lineWidth: 1)
    }

    @ViewBuilder
    private func searchResultAction(for profile: ProfileRow) -> some View {
        switch session.friendshipRelation(with: profile.id) {
        case .accepted:
            statusTag("FRIENDS")
        case .outgoingPending:
            statusTag("PENDING")
        case .incomingPending(let friendshipId):
            Button {
                Task { await acceptByID(friendshipId, name: profile.displayName) }
            } label: {
                Group {
                    if acceptingRequestID == friendshipId {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("ACCEPT")
                            .font(FishedexFont.caption)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(FishedexTheme.tabGreen)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
            }
            .buttonStyle(.plain)
        case .none:
            Button {
                Task { await addFriend(profile) }
            } label: {
                Group {
                    if isAdding {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("ADD")
                            .font(FishedexFont.caption)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(FishedexTheme.tabGreen)
                .fishedexSquare()
                .fishedexBorder(lineWidth: 1)
            }
            .buttonStyle(.plain)
            .disabled(isAdding)
        }
    }

    private func friendRow(_ profile: ProfileRow, statusTag: String?) -> some View {
        HStack(spacing: 12) {
            ProfileAvatarView(urlString: profile.avatarUrl, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text((profile.displayName ?? "ANGLER").uppercased())
                    .font(FishedexFont.caption)
                    .foregroundStyle(FishedexTheme.ink)
                Text("LV. \(profile.level) · \((profile.statusTitle).uppercased())")
                    .font(FishedexFont.micro)
                    .foregroundStyle(FishedexTheme.muted)
            }

            Spacer()

            if let statusTag {
                self.statusTag(statusTag)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(FishedexTheme.muted)
            }
        }
        .padding(10)
        .background(Color.white)
        .fishedexSquare()
        .fishedexBorder(lineWidth: 1)
    }

    private func statusTag(_ label: String) -> some View {
        Text(label)
            .font(FishedexFont.micro)
            .foregroundStyle(label == "PENDING" ? FishedexTheme.muted : FishedexTheme.ocean)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white)
            .fishedexSquare()
            .fishedexBorder(lineWidth: 1)
    }

    private func searchFriend() async {
        isSearching = true
        friendsMessage = nil
        searchResult = nil
        defer { isSearching = false }

        do {
            if let result = try await session.searchUserByEmail(emailQuery) {
                searchResult = result
            } else {
                friendsMessage = "No angler found with that email."
            }
        } catch {
            friendsMessage = error.localizedDescription
        }
    }

    private func addFriend(_ profile: ProfileRow) async {
        isAdding = true
        friendsMessage = nil
        defer { isAdding = false }

        do {
            try await session.addFriend(profile: profile)
            friendsMessage = "Friend request sent to \((profile.displayName ?? "angler").uppercased())."
            searchResult = nil
            emailQuery = ""
        } catch {
            friendsMessage = error.localizedDescription
        }
    }

    private func acceptRequest(_ request: FriendRequest) async {
        await acceptByID(request.friendshipId, name: request.requester.displayName)
    }

    private func acceptByID(_ friendshipId: UUID, name: String?) async {
        acceptingRequestID = friendshipId
        friendsMessage = nil
        defer { acceptingRequestID = nil }

        do {
            try await session.acceptFriendRequest(friendshipId: friendshipId)
            friendsMessage = "You and \((name ?? "angler").uppercased()) are now friends."
            searchResult = nil
            emailQuery = ""
        } catch {
            friendsMessage = error.localizedDescription
        }
    }

    private func declineRequest(_ request: FriendRequest) async {
        decliningRequestID = request.friendshipId
        friendsMessage = nil
        defer { decliningRequestID = nil }

        do {
            try await session.declineFriendRequest(friendshipId: request.friendshipId)
            friendsMessage = "Friend request declined."
        } catch {
            friendsMessage = error.localizedDescription
        }
    }
}
