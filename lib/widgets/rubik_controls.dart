import 'package:flutter/material.dart';

/// Widget hiển thị các nút điều khiển Rubik's Cube
class RubikControls extends StatelessWidget {
  final bool isRotating;
  final bool isAutoSwapping;
  final bool isAutoSolving;
  final VoidCallback onRotateR;
  final VoidCallback onRotateRPrime;
  final VoidCallback onRotateL;
  final VoidCallback onRotateLPrime;
  final VoidCallback onRotateU;
  final VoidCallback onRotateUPrime;
  final VoidCallback onRotateD;
  final VoidCallback onRotateDPrime;
  final VoidCallback onRotateF;
  final VoidCallback onRotateFPrime;
  final VoidCallback onRotateB;
  final VoidCallback onRotateBPrime;
  final VoidCallback onRotateM;
  final VoidCallback onRotateMPrime;
  final VoidCallback onRotateE;
  final VoidCallback onRotateEPrime;
  final VoidCallback onRotateS;
  final VoidCallback onRotateSPrime;
  final VoidCallback onAutoSwap;
  final VoidCallback onAutoSolve;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const RubikControls({
    Key? key,
    required this.isRotating,
    required this.isAutoSwapping,
    required this.isAutoSolving,
    required this.onRotateR,
    required this.onRotateRPrime,
    required this.onRotateL,
    required this.onRotateLPrime,
    required this.onRotateU,
    required this.onRotateUPrime,
    required this.onRotateD,
    required this.onRotateDPrime,
    required this.onRotateF,
    required this.onRotateFPrime,
    required this.onRotateB,
    required this.onRotateBPrime,
    required this.onRotateM,
    required this.onRotateMPrime,
    required this.onRotateE,
    required this.onRotateEPrime,
    required this.onRotateS,
    required this.onRotateSPrime,
    required this.onAutoSwap,
    required this.onAutoSolve,
    required this.onStop,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              '🎮 Công Thức Giải Rubik',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '(R: Phải, L: Trái, U: Trên, D: Dưới, F: Trước, B: Sau)',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 2),
            const Text(
              '(M: Giữa-X, E: Giữa-Y, S: Giữa-Z)',
              style: TextStyle(color: Colors.white60, fontSize: 10),
            ),
            const SizedBox(height: 12),

            // Hàng 1: R, R', L, L'
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNotationButton('R', Colors.blue, onRotateR, isRotating),
                _buildNotationButton('R\'', Colors.blue[300]!, onRotateRPrime, isRotating),
                _buildNotationButton('L', Colors.green, onRotateL, isRotating),
                _buildNotationButton('L\'', Colors.green[300]!, onRotateLPrime, isRotating),
              ],
            ),
            const SizedBox(height: 8),

            // Hàng 2: U, U', D, D'
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNotationButton('U', Colors.red, onRotateU, isRotating),
                _buildNotationButton('U\'', Colors.red[300]!, onRotateUPrime, isRotating),
                _buildNotationButton('D', Colors.orange, onRotateD, isRotating),
                _buildNotationButton('D\'', Colors.orange[300]!, onRotateDPrime, isRotating),
              ],
            ),
            const SizedBox(height: 8),

            // Hàng 3: F, F', B, B'
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNotationButton('F', Colors.white, onRotateF, isRotating),
                _buildNotationButton('F\'', Colors.white70, onRotateFPrime, isRotating),
                _buildNotationButton('B', Colors.yellow, onRotateB, isRotating),
                _buildNotationButton('B\'', Colors.yellow[300]!, onRotateBPrime, isRotating),
              ],
            ),
            const SizedBox(height: 8),

            // Hàng 4: M, M', E, E', S, S'
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNotationButton('M', Colors.teal, onRotateM, isRotating),
                    _buildNotationButton('M\'', Colors.teal[300]!, onRotateMPrime, isRotating),
                    _buildNotationButton('E', Colors.purple, onRotateE, isRotating),
                    _buildNotationButton('E\'', Colors.purple[300]!, onRotateEPrime, isRotating),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNotationButton('S', Colors.indigo, onRotateS, isRotating),
                    _buildNotationButton('S\'', Colors.indigo[300]!, onRotateSPrime, isRotating),
                    const Expanded(child: SizedBox()),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hàng 5: Auto Swap và Auto Solve
            const Text(
              '🤖 Chức Năng Tự Động',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAutoButton(
                  '🎲',
                  isAutoSwapping ? Colors.grey : Colors.deepOrange,
                  isAutoSwapping ? 'Đang xáo...' : 'Tự Xáo',
                  onAutoSwap,
                  isAutoSwapping || isRotating,
                ),
                _buildAutoButton(
                  '🧠',
                  isAutoSolving ? Colors.grey : Colors.green,
                  isAutoSolving ? 'Đang giải...' : 'Tự Giải',
                  onAutoSolve,
                  isAutoSolving || isRotating,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Nút dừng và reset
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isAutoSwapping || isAutoSolving)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onStop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stop, size: 18),
                          SizedBox(width: 6),
                          Text('Dừng',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                if (isAutoSwapping || isAutoSolving)
                  const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (isRotating || isAutoSwapping || isAutoSolving)
                        ? null
                        : onReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 18),
                        SizedBox(width: 6),
                        Text('Reset',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotationButton(
    String notation,
    Color color,
    VoidCallback onPressed,
    bool isRotating,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: ElevatedButton(
          onPressed: isRotating ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: color == Colors.white || color == Colors.white70
                ? Colors.black
                : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 4,
          ),
          child: Text(
            notation,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoButton(
    String icon,
    Color color,
    String text,
    VoidCallback onPressed,
    bool isDisabled,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: isDisabled ? 2 : 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isDisabled && (isAutoSwapping || isAutoSolving))
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Text(
                  icon,
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

