//
//  OnBoardingView.swift
//  Bosswift
//
//  Created by huikai on 2022/6/17.
//

import SwiftUI

struct OnBoardingView: View {
    enum Step {
        case welcome, setup
    }

    @State var currentStep = Step.welcome

    var body: some View {
        ScrollView {
            VStack {
                switch currentStep {
                case .welcome:
                    WelcomeView(onNextStep: { currentStep = .setup })
                case .setup:
                    SetupView()
                }
            }
        }
    }
}

struct OnBoardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnBoardingView()
    }
}
