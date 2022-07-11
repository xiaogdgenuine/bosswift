//
//  BranchPickerView.swift
//  Bosswift
//
//  Created by huikai on 2022/6/18.
//

import SwiftUI

struct BranchPickerView: View {
    let keyword: String
    let highlightingRow: Int
    let candidateBranches: [Branch]
    let executeItemAt: (Int) -> Void
    @State var branchOffset = 0
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 0) {
                    ForEach(Array(candidateBranches.enumerated()), id: \.offset) { (index, branch) in
                        let hightlight = index == highlightingRow

                        BranchPickerItemRowView(branch: branch, currentKeyword: keyword, hightlight: hightlight,
                                                index: index, branchIndexBegin: branchOffset)
                            .frame(height: candidateRowHeight)
                            .onTapGesture {
                                executeItemAt(index)
                            }
                            .id(index)
                    }
                }
                .padding(.trailing, 16)
                .onChange(of: highlightingRow) { row in
                    proxy.scrollTo(row)
                }
            }
        }
        .didScroll { offset in
            branchOffset = Int(ceil(offset.y) / candidateRowHeight)
        }

        QuickLaunchShortcuts { index in
            executeItemAt(index + branchOffset)
        }
        .frame(width: 0, height: 0)
        .clipped()
    }
}

struct BranchPickerItemRowView: View {
    @ObservedObject var branch: Branch
    let currentKeyword: String
    let hightlight: Bool
    let index: Int
    let branchIndexBegin: Int
    @State var highlightByHover = false
    @State var mouseMoved = false
    @ObservedObject var mouseMoveMonitor = MouseMoveMonitor.shared

    var body: some View {
        let highlightableBranchName = generateHighlightableText(keyword: currentKeyword, candidate: branch.displayName)

        HStack {
            VStack(alignment: .leading) {
                if let highlightableText = highlightableBranchName {
                    Group {
                        Text(highlightableText.begin)
                             +
                        Text(highlightableText.middle)
                            .foregroundColor(Color.orange)
                            .underline() +
                        Text(highlightableText.end)
                    }.font(.system(size: 16))
                } else {
                    LeadingTextView(branch.displayName)
                        .font(.system(size: 16))
                }

                Group {
                    let projectHasNickName = appSetting.projectNameMappings$[branch.project.name] != nil
                    if highlightableBranchName == nil, let highlightableText = generateHighlightableText(keyword: currentKeyword, candidate: branch.project.displayName) {
                        Text(highlightableText.begin)
                             +
                        Text(highlightableText.middle)
                            .foregroundColor(Color.orange)
                            .underline() +
                        Text(highlightableText.end) +
                        Text(projectHasNickName ? "(\(branch.project.name))" : "")
                    } else {
                        Text(branch.project.displayName) +
                        Text(projectHasNickName ? "(\(branch.project.name))" : "")
                    }
                }
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
            Spacer()

            if hightlight {
                Image("EnterKey")
                    .resizable()
                    .frame(width: 20, height: 20)
            } else {
                HStack {
                    Image(systemName: "command")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("\(index - branchIndexBegin + 1)")
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
        .padding(.vertical)
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
        .onHover {
            highlightByHover = $0
        }
        .background((highlightByHover && mouseMoveMonitor.mouseMoved) ? Color.accentColor.opacity(0.7) : hightlight ? Color.accentColor : Color(NSColor.textBackgroundColor))
        .cornerRadius(4)
    }
}

struct BranchPickerView_Previews: PreviewProvider {
    static var previews: some View {
        BranchPickerView(keyword: "", highlightingRow: 0, candidateBranches: []) { _ in
        }
    }
}
