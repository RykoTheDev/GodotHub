import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class GhEqualHeightRow extends MultiChildRenderObjectWidget {
  const GhEqualHeightRow({super.key, required this.columns, this.spacing = 0, required super.children});

  final int columns;
  final double spacing;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderEqualHeightRow(columns: columns, spacing: spacing, textDirection: Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderEqualHeightRow renderObject) {
    renderObject
      ..columns = columns
      ..spacing = spacing
      ..textDirection = Directionality.of(context);
  }
}

class _EqualHeightParentData extends ContainerBoxParentData<RenderBox> {}

class RenderEqualHeightRow extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _EqualHeightParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _EqualHeightParentData> {
  RenderEqualHeightRow({required this._columns, required this._spacing, required this._textDirection});

  int _columns;
  double _spacing;
  TextDirection _textDirection;

  set columns(int value) {
    if (value == _columns) return;
    _columns = value;
    markNeedsLayout();
  }

  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EqualHeightParentData) child.parentData = _EqualHeightParentData();
  }

  double _columnWidth(double width) => math.max(0, (width - _spacing * (_columns - 1)) / _columns);

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final columnWidth = _columnWidth(width);
    var height = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(BoxConstraints(minWidth: columnWidth, maxWidth: columnWidth), parentUsesSize: true);
      height = math.max(height, child.size.height);
      child = childAfter(child);
    }
    var index = 0;
    child = firstChild;
    while (child != null) {
      child.layout(BoxConstraints.tightFor(width: columnWidth, height: height));
      final x = (columnWidth + _spacing) * index;
      (child.parentData! as _EqualHeightParentData).offset = Offset(_textDirection == TextDirection.rtl ? width - x - columnWidth : x, 0);
      index++;
      child = childAfter(child);
    }
    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}

class GhEqualWidthColumn extends MultiChildRenderObjectWidget {
  const GhEqualWidthColumn({super.key, this.spacing = 0, required super.children});

  final double spacing;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderEqualWidthColumn(spacing: spacing);

  @override
  void updateRenderObject(BuildContext context, RenderEqualWidthColumn renderObject) => renderObject.spacing = spacing;
}

class RenderEqualWidthColumn extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _EqualHeightParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _EqualHeightParentData> {
  RenderEqualWidthColumn({required this._spacing});

  double _spacing;

  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EqualHeightParentData) child.parentData = _EqualHeightParentData();
  }

  @override
  void performLayout() {
    var width = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(BoxConstraints(maxWidth: constraints.maxWidth), parentUsesSize: true);
      width = math.max(width, child.size.width);
      child = childAfter(child);
    }
    var y = 0.0;
    child = firstChild;
    while (child != null) {
      child.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      (child.parentData! as _EqualHeightParentData).offset = Offset(0, y);
      y += child.size.height;
      child = childAfter(child);
      if (child != null) y += _spacing;
    }
    size = constraints.constrain(Size(width, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}
