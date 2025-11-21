import SwiftUI

struct AddEditTimerView: View {
    @Binding var task: TaskTimer?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var minutes: Double = 5

    var onSave: (String, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    Stepper(value: $minutes, in: 1...180, step: 1) {
                        Text("Duration: \(Int(minutes)) minutes")
                    }
                }
            }
            .navigationTitle(task == nil ? "Add Timer" : "Edit Timer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), Int(minutes))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let task {
                    name = task.name
                    minutes = Double(task.duration / 60)
                }
            }
        }
    }
}

#Preview {
    AddEditTimerView(task: .constant(nil)) { _, _ in }
}
