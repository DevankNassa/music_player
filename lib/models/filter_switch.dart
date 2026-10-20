enum SwitchPosition { exclude, neutral, require }

class FilterSwitch {
  String? tag;
  SwitchPosition position;

  FilterSwitch({this.tag, this.position = SwitchPosition.neutral});
}
