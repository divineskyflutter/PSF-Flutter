/// The two shapes the member card can be shown (and downloaded) in. The
/// member picks one with the switch in the wallet; the choice lives in
/// `MemberCardController.layout`.
enum MemberCardLayout { horizontal, vertical }

/// Whether the Horizontal | Vertical switch shows in the wallet. Turned off
/// for now — only the horizontal (printed-style) card is shown, per
/// request. The vertical card, the switch widget and the switching code are
/// all untouched; flip this back to `true` to bring the switch back.
const bool kShowCardLayoutSwitch = false;
