import CNozzle

public enum Discovery {
    public static func enumerateSenders() throws -> [SenderInfo] {
        var array = CNozzle.NozzleSenderInfoArray()
        try check(nozzle_enumerate_senders(&array))
        defer { nozzle_free_sender_info_array(&array) }

        guard let items = array.items, array.count > 0 else { return [] }

        return (0..<Int(array.count)).map { i in
            SenderInfo(items[i])
        }
    }
}
