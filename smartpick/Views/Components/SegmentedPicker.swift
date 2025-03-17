import SwiftUI

struct SegmentedPicker: View {
    let title: String
    let values: [Int]
    @Binding var selection: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: {
                        selection = -1
                    }) {
                        Text("自動")
                            .frame(minWidth: 60)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selection == -1 ? Color.blue : Color(.systemGray6))
                            )
                            .foregroundColor(selection == -1 ? .white : .primary)
                    }
                    
                    ForEach(values, id: \.self) { value in
                        Button(action: {
                            selection = value
                        }) {
                            Text("\(value)")
                                .frame(minWidth: 60)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selection == value ? Color.blue : Color(.systemGray6))
                                )
                                .foregroundColor(selection == value ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

#Preview {
    SegmentedPicker(
        title: "40以上の数字",
        values: Array(0...3),
        selection: .constant(1)
    )
    .padding()
} 