public struct SymphonyCodexConnectionPresenter {
    public init() {}

    public func present(
        _ status: SymphonyCodexConnectionStatusContract
    ) -> SymphonyCodexConnectionViewModel {
        let details = detailMessage(for: status)

        switch status.state {
        case .connected:
            return SymphonyCodexConnectionViewModel(
                isConnected: true,
                title: "Codex Ready",
                message: details
            )
        case .cliUnavailable:
            return SymphonyCodexConnectionViewModel(
                isConnected: false,
                title: "Codex CLI Missing",
                message: details
            )
        case .notAuthenticated:
            return SymphonyCodexConnectionViewModel(
                isConnected: false,
                title: "Codex Login Required",
                message: details
            )
        case .appServerUnavailable:
            return SymphonyCodexConnectionViewModel(
                isConnected: false,
                title: "Codex App Server Unavailable",
                message: details
            )
        }
    }

    private func detailMessage(
        for status: SymphonyCodexConnectionStatusContract
    ) -> String {
        var lines: [String] = [status.statusMessage]

        if let executablePath = status.executablePath,
           executablePath.isEmpty == false {
            lines.append("CLI path: \(executablePath)")
        }

        if let detailMessage = status.detailMessage,
           detailMessage.isEmpty == false {
            lines.append(detailMessage)
        }

        return lines.joined(separator: "\n\n")
    }
}
