package com.devanknassa.insta_playlist

import com.ryanheise.audioservice.AudioServiceActivity

// audio_service needs the activity to share its FlutterEngine with the
// background playback service that owns the media notification.
class MainActivity : AudioServiceActivity()
