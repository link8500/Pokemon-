import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon/widgets/resume_repaint_boundary.dart';

void main() {
  testWidgets(
    'returning from background repaints without losing input or scroll',
    (tester) async {
      final text = TextEditingController(text: 'dito');
      final scroll = ScrollController();
      addTearDown(text.dispose);
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ResumeRepaintBoundary(
            child: Scaffold(
              body: ListView(
                controller: scroll,
                children: [
                  TextField(controller: text),
                  for (var i = 0; i < 50; i++)
                    SizedBox(height: 60, child: Text('Pokémon $i')),
                ],
              ),
            ),
          ),
        ),
      );
      scroll.jumpTo(100);
      await tester.pump();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find
            .descendant(
              of: find.byType(ResumeRepaintBoundary),
              matching: find.byType(RepaintBoundary),
            )
            .first,
      );
      expect(boundary.debugNeedsPaint, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(boundary.debugNeedsPaint, isTrue);
      await tester.pump();
      expect(boundary.debugNeedsPaint, isFalse);
      expect(text.text, 'dito');
      expect(scroll.offset, 100);
      // Disposing removes the observer, so later lifecycle events are harmless.
      await tester.pumpWidget(const SizedBox.shrink());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(tester.takeException(), isNull);
    },
  );
}
