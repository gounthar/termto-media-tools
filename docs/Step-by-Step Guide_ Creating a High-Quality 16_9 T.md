## Step-by-Step Guide: Creating a High-Quality 16:9 Terminal Video for PowerPoint Using Termtosvg

This guide will walk you through recording your terminal session with `termtosvg`, converting it to a high-resolution 16:9 MP4 video, and ensuring the result is fully compatible with PowerPoint.

---

### **1. Record Your Terminal Session with termtosvg**

**Install termtosvg (if not already installed):**

```bash
pip3 install --user termtosvg
```

*You may also need:*

```bash
pip3 install --user pyte python-xlib svgwrite
```

**Start recording:**

```bash
termtosvg -g 120x34 mysession.svg
```

- `-g 120x34` sets the terminal geometry. For a true 16:9 ratio, use a geometry where width/height ≈ 1.777 (16/9). For example, 120x34 (120/34 ≈ 3.53) is wider than 16:9, so you might prefer 160x45 (160/45 ≈ 3.56) or 128x36 (128/36 ≈ 3.55). You can also use 96x27 (96/27 ≈ 3.56) for smaller recordings.
- Adjust as needed for your content and font size.

**End recording:**

- Type `exit` or press `Ctrl+D` when finished[^1][^10].

---

### **2. Convert SVG Animation to Video**

#### **Option A: Use a Dedicated SVG-to-Video Service (Recommended for Quality and Simplicity)**

- Use an online SVG-to-video converter (e.g., SVGator, html5animationtogif.com)[^4][^8].
- Upload your SVG file.
- Set output to MP4, select your desired resolution (e.g., 1920x1080 or 3840x2160 for 4K).
- Download the resulting MP4.

**Pros:** High-quality, easy, supports 16:9, no local dependencies.
**Cons:** May have duration or size limits for free users.

#### **Option B: Convert Asciicast to Video via Docker (If you have a .cast file)**

If you recorded in asciicast format:

```bash
termtosvg record mysession.cast
```

Then use the Docker tool:

```bash
docker run --rm -v $PWD:/data beer5215/asciicast2mp4 \
  -S 4 -w 160 -h 45 mysession.cast
```

- This will output `result.mp4` in your current directory, at high resolution (pixel density 4, 160x45 terminal size)[see prior guidance].

**Rename the result for clarity:**

```bash
mv result.mp4 mysession-highres.mp4
```


#### **Option C: Upscale with FFmpeg (Optional, for further quality or resizing)**

If you want to ensure a standard 16:9 resolution (e.g., 1920x1080):

```bash
ffmpeg -i mysession-highres.mp4 -vf "scale=1920:1080:flags=lanczos" upscale.mp4
```

- The `lanczos` filter preserves sharpness.

---

### **3. Ensure PowerPoint Compatibility with FFmpeg**

PowerPoint prefers MP4 files with H.264 video and AAC audio, using the High profile and yuv420p pixel format[^5][^6][^9].

**Final conversion (if needed):**

```bash
ffmpeg -i upscale.mp4 \
  -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p \
  -an -movflags +faststart -preset slow \
  pptx-compatible.mp4
```

- `-an` disables audio (since terminal videos usually don't need it).
- `-movflags +faststart` ensures smooth playback in PowerPoint.

---

### **4. Verify the Video**

Check the output dimensions and format:

```bash
ffprobe -v error -select_streams v:0 -show_entries stream=width,height,display_aspect_ratio -of csv=s=x:p=0 pptx-compatible.mp4
```

- Should return something like `1920x1080x16:9`.

---

### **5. Insert the Video into PowerPoint**

- Open your PowerPoint presentation.
- Go to **Insert > Video > Video on My PC...** and select your `pptx-compatible.mp4`.
- Set playback options as needed (autoplay, loop, etc.).

---

## **Summary Table**

| Step | Tool | Command/Action | Notes |
| :-- | :-- | :-- | :-- |
| 1 | termtosvg | `termtosvg -g 160x45 mysession.svg` | 16:9 geometry |
| 2A | SVGator/Online | Upload SVG, export MP4 | Choose 16:9 resolution |
| 2B | Docker | `docker run ... beer5215/asciicast2mp4 ...` | For .cast files |
| 2C | FFmpeg | `ffmpeg -i ... -vf "scale=1920:1080:flags=lanczos"` | Optional upscaling |
| 3 | FFmpeg | `ffmpeg -i ... -c:v libx264 ... -pix_fmt yuv420p ...` | Ensures compatibility |
| 4 | FFprobe | `ffprobe -v error ...` | Verify output |
| 5 | PowerPoint | Insert video | Set playback options |


---

## **Tips**

- Always check your video in PowerPoint before presenting.
- If you need transparency or advanced effects, consider using MOV/WebM from SVGator[^8].
- For longer or complex animations, online converters may have limits; use Docker/FFmpeg locally for full control.

---

By following these steps, you will produce a crisp, professional, high-resolution terminal video that looks great in any PowerPoint presentation[^1][^3][^4][^5][^6][^8][^9][^10].

<div style="text-align: center">⁂</div>

[^1]: https://nbedos.github.io/termtosvg/

[^2]: https://github.com/MrMarble/termsvg

[^3]: https://www.linuxlinks.com/termtosvg-terminal-recorder-python/

[^4]: https://html5animationtogif.com/svg-to-video

[^5]: https://stackoverflow.com/questions/44130350/convert-videos-with-ffmpeg-to-powerpoint-2016-compatible-video-format

[^6]: https://videoconvert.minitool.com/news/convert-video-for-powerpoint.html

[^7]: https://en.ubunlog.com/termtosvg-record-terminal-session/

[^8]: https://www.svgator.com/svg-to-video

[^9]: https://stackoverflow.com/a/51097502

[^10]: https://ostechnix.com/how-to-record-terminal-sessions-as-svg-animations-in-linux/

[^11]: https://www.reddit.com/r/commandline/comments/13bhdg1/termtosvg_record_terminal_sessions_as_svg/