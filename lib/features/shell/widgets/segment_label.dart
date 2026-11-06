import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The scale that fits a one-line label of [natural] size into
/// [constraints]: 1 when it fits, less when it is too wide or too tall.
double labelFitScale(Size natural, BoxConstraints constraints) {
  if (natural.isEmpty) return 1;
  final wide = constraints.hasBoundedWidth ? constraints.maxWidth / natural.width : 1.0;
  final tall = constraints.hasBoundedHeight ? constraints.maxHeight / natural.height : 1.0;
  return math.min(1, math.min(wide, tall));
}

/// The one scale every label of a group is drawn at: the smallest any of
/// them needs, so neighbouring labels stay the same size.
double sharedLabelScale(Iterable<double> needs) => needs.fold(1, math.min);

/// A segmented button or tab label kept on one line. Too big for its segment,
/// it is drawn smaller rather than wrapped or clipped, and every label inside
/// the same [SegmentedButton] or [TabBar] is drawn at the same scale.
class SegmentLabel extends SingleChildRenderObjectWidget {
  SegmentLabel(String label, {super.key, Key? textKey}) : super(child: Text(label, key: textKey, maxLines: 1, softWrap: false));

  @override
  RenderSegmentLabel createRenderObject(BuildContext context) => RenderSegmentLabel(_groupOf(context));

  @override
  void updateRenderObject(BuildContext context, RenderSegmentLabel renderObject) => renderObject.group = _groupOf(context);

  static final _groups = Expando<SegmentLabelGroup>();

  /// The labels of one segmented button or tab bar share a group; a label
  /// outside one stands alone.
  static SegmentLabelGroup? _groupOf(BuildContext context) {
    Element? button;
    context.visitAncestorElements((element) {
      if (element.widget is! SegmentedButton && element.widget is! TabBar) return true;
      button = element;
      return false;
    });
    final found = button;
    return found == null ? null : _groups[found] ??= SegmentLabelGroup();
  }
}

/// What each label of one segmented button or tab bar needs, so all draw at
/// the smallest. Labels report during layout; the shared scale is read at
/// paint, after the whole button has laid out.
class SegmentLabelGroup {
  final _needs = <RenderSegmentLabel, double>{};

  double get scale => sharedLabelScale(_needs.values);

  void report(RenderSegmentLabel label, double need) {
    if (_needs[label] == need) return;
    _needs[label] = need;
    _repaintOthers(label);
  }

  void remove(RenderSegmentLabel label) {
    if (_needs.remove(label) != null) _repaintOthers(label);
  }

  void _repaintOthers(RenderSegmentLabel label) {
    for (final other in _needs.keys) {
      if (!identical(other, label)) other.markNeedsPaint();
    }
  }
}

class RenderSegmentLabel extends RenderProxyBox {
  RenderSegmentLabel(this._group);

  SegmentLabelGroup? _group;
  set group(SegmentLabelGroup? value) {
    if (identical(value, _group)) return;
    _group?.remove(this);
    _group = value;
    markNeedsLayout();
  }

  /// The scale this label alone would need.
  double _need = 1;

  double get _scale => math.min(_need, _group?.scale ?? 1);

  /// Centres the child, drawn at [_scale], in this box.
  Matrix4 get _paintTransform {
    final scale = _scale;
    final childSize = child!.size;
    return Matrix4.translationValues((size.width - childSize.width * scale) / 2, (size.height - childSize.height * scale) / 2, 0)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (hasSize) _group?.report(this, _need);
  }

  @override
  void detach() {
    _group?.remove(this);
    super.detach();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final natural = child.getDryLayout(const BoxConstraints());
    return constraints.constrain(natural * labelFitScale(natural, constraints));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(const BoxConstraints(), parentUsesSize: true);
    _need = labelFitScale(child.size, constraints);
    size = constraints.constrain(child.size * _need);
    _group?.report(this, _need);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    layer = context.pushTransform(needsCompositing, offset, _paintTransform, (context, offset) => context.paintChild(child!, offset), oldLayer: layer as TransformLayer?);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.multiply(_paintTransform);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintTransform(transform: _paintTransform, position: position, hitTest: (result, position) => child.hitTest(result, position: position));
  }
}
