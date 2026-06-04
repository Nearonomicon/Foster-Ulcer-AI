part of '../widgets/main_navigation_screen.dart';

extension _CameraPage on _MainNavigationScreenState {
  Widget _buildARCamera() {
    final showPreview = _woundPhotoAwaitingConfirmation && _capturedImage != null;
    if (!_woundCameraInitializing &&
        _woundCameraController == null &&
        _woundCameraError == null &&
        !showPreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initWoundCamera());
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: showPreview
                ? Image.file(
                    File(_capturedImage!.path),
                    fit: BoxFit.cover,
                  )
                : _woundCameraController?.value.isInitialized == true
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _woundCameraController!.value.previewSize!.height,
                          height: _woundCameraController!.value.previewSize!.width,
                          child: cam.CameraPreview(_woundCameraController!),
                        ),
                      )
                    : Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: _woundCameraError != null
                            ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.cameraOff, color: Colors.white70, size: 36),
                                    const SizedBox(height: 12),
                                    Text(
                                      _woundCameraError!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton(
                                      onPressed: _initWoundCamera,
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                                      child: const Text("Retry Camera"),
                                    ),
                                  ],
                                ),
                              )
                            : const CircularProgressIndicator(color: Colors.white),
                      ),
          ),
          if (showPreview)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            )
          else
            Center(
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _woundCaptureBlocked ? Colors.orangeAccent : Colors.greenAccent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Center(
                    child: Text(
                      "ALIGN WOUND",
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black38,
                      child: IconButton(icon: const Icon(LucideIcons.x, color: Colors.white), onPressed: () => _navigateTo('vital_check_page')),
                    ),
                    ElevatedButton.icon(
                      onPressed: showPreview ? _retakeWoundPhoto : () => _pickImage(ImageSource.gallery),
                      icon: Icon(showPreview ? LucideIcons.rotateCcw : LucideIcons.folderOpen, size: 16),
                      label: Text(showPreview ? "RETAKE" : "BROWSE"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white, shape: const StadiumBorder()),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showPreview) ...[
                        const Text(
                          "Preview wound photo",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Retake if the wound is unclear, or use this photo to continue AI extraction.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _woundCaptureBlocked ? Colors.orangeAccent : Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _woundGuidanceMessage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCameraMetricChip(
                                label: 'Lighting',
                                value: _woundBrightnessScore < 55
                                    ? 'Low'
                                    : _woundBrightnessScore > 210
                                        ? 'High'
                                        : 'Good',
                                color: _woundBrightnessScore < 55 || _woundBrightnessScore > 210
                                    ? Colors.orangeAccent
                                    : Colors.greenAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCameraMetricChip(
                                label: 'Motion',
                                value: _woundMotionScore > 22 ? 'Unsteady' : 'Stable',
                                color: _woundMotionScore > 22 ? Colors.orangeAccent : Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    showPreview
                        ? "CONFIRM PHOTO"
                        : _woundCaptureBlocked
                            ? "WAIT FOR BETTER FRAME"
                            : "READY TO CAPTURE",
                    style: TextStyle(
                      color: showPreview
                          ? Colors.white
                          : _woundCaptureBlocked
                              ? Colors.orangeAccent
                              : Colors.greenAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (showPreview)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _retakeWoundPhoto,
                            icon: const Icon(LucideIcons.rotateCcw, size: 16),
                            label: const Text("Retake"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _confirmWoundPhotoForFillin,
                            icon: const Icon(LucideIcons.check, size: 16),
                            label: const Text("Use Photo"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: _captureWoundPhoto,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _woundCaptureBlocked ? Colors.white54 : Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: _woundCaptureBlocked ? const Color(0xFF64748B) : const Color(0xFF0D9488),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraMetricChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
