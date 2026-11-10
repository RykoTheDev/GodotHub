import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class GhNegativeMargin extends SingleChildRenderObjectWidget {
  const GhNegativeMargin({super.key, required this.margin, super.child});

  final EdgeInsets margin;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderGhNegativeMargin(margin);

  @override
  void updateRenderObject(BuildContext context, RenderGhNegativeMargin renderObject) {
    renderObject.margin = margin;
  }
}

class RenderGhNegativeMargin extends RenderShiftedBox {
  RenderGhNegativeMargin(this._margin) : super(null);

  EdgeInsets _margin;

  set margin(EdgeInsets value) {
    if (value == _margin) {
      return;
    }
    _margin = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    final h = _margin.horizontal;
    final v = _margin.vertical;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final inner = BoxConstraints(
      minWidth: constraints.minWidth + h,
      maxWidth: constraints.maxWidth + h,
      minHeight: constraints.minHeight + v,
      maxHeight: constraints.maxHeight + v,
    );
    child.layout(inner, parentUsesSize: true);
    size = constraints.constrain(Size(child.size.width - h, child.size.height - v));
    (child.parentData! as BoxParentData).offset = Offset(-_margin.left, -_margin.top);
  }

  @override
  double computeMinIntrinsicWidth(double height) => (child?.getMinIntrinsicWidth(height + _margin.vertical) ?? 0) - _margin.horizontal;

  @override
  double computeMaxIntrinsicWidth(double height) => (child?.getMaxIntrinsicWidth(height + _margin.vertical) ?? 0) - _margin.horizontal;

  @override
  double computeMinIntrinsicHeight(double width) => (child?.getMinIntrinsicHeight(width + _margin.horizontal) ?? 0) - _margin.vertical;

  @override
  double computeMaxIntrinsicHeight(double width) => (child?.getMaxIntrinsicHeight(width + _margin.horizontal) ?? 0) - _margin.vertical;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) {
      return constraints.smallest;
    }
    final h = _margin.horizontal;
    final v = _margin.vertical;
    final inner = BoxConstraints(
      minWidth: constraints.minWidth + h,
      maxWidth: constraints.maxWidth + h,
      minHeight: constraints.minHeight + v,
      maxHeight: constraints.maxHeight + v,
    );
    final childSize = child.getDryLayout(inner);
    return constraints.constrain(Size(childSize.width - h, childSize.height - v));
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_margin.inflateRect(Offset.zero & size).contains(position)) {
      return false;
    }
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
