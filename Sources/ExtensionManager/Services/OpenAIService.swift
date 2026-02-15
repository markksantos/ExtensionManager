import Foundation

struct OpenAIService {
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }

    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let max_tokens: Int
        let temperature: Double
    }

    struct ChatResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }

    static func analyzeExtension(bundleID: String, displayName: String, parentName: String, category: String, apiKey: String) async -> String? {
        guard !apiKey.isEmpty else { return nil }

        let prompt = """
        Briefly describe this macOS system extension in 1-2 sentences. What does it do and is it safe/necessary?

        Bundle ID: \(bundleID)
        Display Name: \(displayName)
        Parent App: \(parentName.isEmpty ? "Unknown" : parentName)
        Extension Type: \(category)

        Be concise. If you recognize the app, mention what it's for. If it seems unnecessary or potentially unwanted, mention that.
        """

        let request = ChatRequest(
            model: "gpt-4o-mini",
            messages: [ChatMessage(role: "user", content: prompt)],
            max_tokens: 150,
            temperature: 0.3
        )

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return nil }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 15

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            return chatResponse.choices.first?.message.content
        } catch {
            return nil
        }
    }
}
