import AppKit

final class CalculatorTab: NSView {
    private let inputField: NSTextField
    private let resultLabel: NSTextField
    private let hintLabel: NSTextField

    override init(frame: NSRect) {
        inputField = NSTextField(frame: .zero)
        resultLabel = NSTextField(frame: .zero)
        hintLabel = NSTextField(frame: .zero)

        super.init(frame: frame)
        wantsLayer = true
        setupInputField()
        setupResultLabel()
        setupHintLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupInputField() {
        inputField.placeholderString = "2 + 2,  sqrt(16),  15% of 200..."
        inputField.isBezeled = false
        inputField.drawsBackground = false
        inputField.font = NSFont.systemFont(ofSize: 20, weight: .light)
        inputField.textColor = .white
        inputField.focusRingType = .none
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.delegate = self

        addSubview(inputField)

        NSLayoutConstraint.activate([
            inputField.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            inputField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            inputField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            inputField.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func setupResultLabel() {
        resultLabel.isEditable = false
        resultLabel.isBezeled = false
        resultLabel.drawsBackground = false
        resultLabel.font = NSFont.systemFont(ofSize: 52, weight: .thin)
        resultLabel.textColor = .white
        resultLabel.alignment = .right
        resultLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(resultLabel)

        NSLayoutConstraint.activate([
            resultLabel.topAnchor.constraint(equalTo: inputField.bottomAnchor, constant: 16),
            resultLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            resultLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            resultLabel.heightAnchor.constraint(equalToConstant: 68),
        ])
    }

    private func setupHintLabel() {
        hintLabel.isEditable = false
        hintLabel.isBezeled = false
        hintLabel.drawsBackground = false
        hintLabel.stringValue = "Enter to copy"
        hintLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        hintLabel.textColor = NSColor.white.withAlphaComponent(0.25)
        hintLabel.alignment = .right
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hintLabel)

        NSLayoutConstraint.activate([
            hintLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 2),
            hintLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            hintLabel.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    // MARK: - Logic (your territory)

    private func evaluate(expression: String) -> String? {
        guard !expression.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        var expr = expression

        // "15% of 200" → "(15/100)*200"
        expr = expr.replacingOccurrences(
            of: #"(\d+\.?\d*)\s*%\s*of\s*(\d+\.?\d*)"#,
            with: "($1/100)*$2",
            options: .regularExpression
        )
        // "15%" → "(15/100)"
        expr = expr.replacingOccurrences(of: #"(\d+\.?\d*)%"#, with: "($1/100)", options: .regularExpression)

        // only allow safe characters to avoid crashing NSExpression
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "+-*/.() "))
        guard expr.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }

        // check balanced parentheses before handing to NSExpression
        var depth = 0
        for c in expr {
            if c == "(" { depth += 1 } else if c == ")" { depth -= 1 }
            if depth < 0 { return nil }
        }
        guard depth == 0 else { return nil }

        let nsExpr = NSExpression(format: expr)
        guard let value = nsExpr.expressionValue(with: nil, context: nil) as? NSNumber else { return nil }
        let d = value.doubleValue
        guard d.isFinite else { return nil }
        return d.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(d)) : String(format: "%g", d)
    }

    // MARK: - Copy result

    private func copyResult() {
        let result = resultLabel.stringValue
        guard !result.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
        flashConfirmation()
    }

    private func flashConfirmation() {
        resultLabel.textColor = .systemGreen
        hintLabel.stringValue = "Copied!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.resultLabel.textColor = .white
            self?.hintLabel.stringValue = "Enter to copy"
        }
    }

    // MARK: - Keyboard

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 {
            copyResult()
        } else {
            super.keyDown(with: event)
        }
    }
}

// MARK: - NSTextFieldDelegate

extension CalculatorTab: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let expr = inputField.stringValue
        if let result = evaluate(expression: expr) {
            resultLabel.stringValue = result
            resultLabel.textColor = .white
        } else {
            resultLabel.stringValue = expr.isEmpty ? "" : "..."
            resultLabel.textColor = NSColor.white.withAlphaComponent(0.3)
        }
    }
}
