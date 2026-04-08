import SwiftUI
import AudioToolbox

enum ButtonSoundPlayer {
    static func playTap() {
        AudioServicesPlaySystemSound(1104)
    }
}

struct SoundDefaultButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .onTapGesture {
                ButtonSoundPlayer.playTap()
                configuration.trigger()
            }
    }
}

struct SoundPlainButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .onTapGesture {
                ButtonSoundPlayer.playTap()
                configuration.trigger()
            }
    }
}

extension PrimitiveButtonStyle where Self == SoundDefaultButtonStyle {
    static var soundDefault: SoundDefaultButtonStyle { SoundDefaultButtonStyle() }
}

extension PrimitiveButtonStyle where Self == SoundPlainButtonStyle {
    static var soundPlain: SoundPlainButtonStyle { SoundPlainButtonStyle() }
}
