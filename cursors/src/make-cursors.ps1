# Generates the RAVYN Neon cursor set (.cur / .ani) into the parent folder, plus preview.png.
param([string]$Out = (Split-Path $PSScriptRoot -Parent))
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.IO; using System.Collections.Generic;
using System.Drawing; using System.Drawing.Drawing2D; using System.Drawing.Imaging;

public static class Cur {
  static Color CYAN = Color.FromArgb(0,240,255), MAG = Color.FromArgb(255,42,109), VIO = Color.FromArgb(176,38,255),
               YEL = Color.FromArgb(252,238,10), RED = Color.FromArgb(255,0,60), DARK = Color.FromArgb(235,10,10,18);
  public static int[] Sizes = new int[] { 32, 48, 64 };

  static GraphicsPath Poly(params float[] p) {
    var g = new GraphicsPath(); var pts = new PointF[p.Length / 2];
    for (int i = 0; i < pts.Length; i++) pts[i] = new PointF(p[2*i], p[2*i+1]);
    g.AddPolygon(pts); return g;
  }
  static GraphicsPath Lines(params float[] p) {
    var g = new GraphicsPath();
    for (int i = 0; i + 3 < p.Length; i += 4) { g.StartFigure(); g.AddLine(p[i], p[i+1], p[i+2], p[i+3]); }
    return g;
  }
  static Pen P(Color c, float w) { var p = new Pen(c, w); p.LineJoin = LineJoin.Miter; p.StartCap = LineCap.Square; p.EndCap = LineCap.Square; return p; }

  // Neon look: soft outer glow, dark body, crisp neon edge.
  static void Neon(Graphics g, GraphicsPath path, bool filled, Color line, Color glow) {
    g.DrawPath(P(Color.FromArgb(40, glow), 5f), path);
    g.DrawPath(P(Color.FromArgb(90, glow), 3f), path);
    if (filled) g.FillPath(new SolidBrush(DARK), path); else g.DrawPath(P(DARK, 3.2f), path);
    g.DrawPath(P(line, 1.35f), path);
  }
  static GraphicsPath Arrow() { return Poly(3,3, 3,25, 9,20, 13,29, 16,28, 12,19, 20,19); }
  static GraphicsPath Rot(GraphicsPath p, float deg) { var m = new Matrix(); m.RotateAt(deg, new PointF(16,16)); p.Transform(m); return p; }
  static GraphicsPath DoubleArrow() { return Poly(2,16, 8,10, 8,14, 24,14, 24,10, 30,16, 24,22, 24,18, 8,18, 8,22); }

  static void Ring(Graphics g, float cx, float cy, float r, float w, int segs, int frame) {
    float span = 360f / segs;
    for (int i = 0; i < segs; i++) {
      int age = ((frame - i) % segs + segs) % segs;          // 0 = head of the spinner
      Color c = age == 0 ? MAG : (age < 4 ? CYAN : Color.FromArgb(60, CYAN));
      float a = i * span - 90;
      var rect = new RectangleF(cx - r, cy - r, 2*r, 2*r);
      if (age < 4) g.DrawArc(new Pen(Color.FromArgb(70, age == 0 ? MAG : CYAN), w + 2.5f), rect, a + 3, span - 6);
      g.DrawArc(new Pen(DARK, w + 1.2f), rect, a + 3, span - 6);
      g.DrawArc(new Pen(c, w), rect, a + 3, span - 6);
    }
  }

  public static Bitmap Render(string kind, int size, int frame) {
    var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb);
    using (var g = Graphics.FromImage(bmp)) {
      g.SmoothingMode = SmoothingMode.AntiAlias; g.Clear(Color.Transparent);
      g.ScaleTransform(size / 32f, size / 32f);
      switch (kind) {
        case "arrow": Neon(g, Arrow(), true, CYAN, MAG); break;
        case "help": Neon(g, Arrow(), true, CYAN, MAG);
          var q = new GraphicsPath(); q.AddString("?", new FontFamily("Cascadia Code"), (int)FontStyle.Bold, 15f, new PointF(17, 9), StringFormat.GenericDefault);
          g.DrawPath(P(DARK, 2.5f), q); g.FillPath(new SolidBrush(YEL), q); break;
        case "working": Neon(g, Arrow(), true, CYAN, MAG); Ring(g, 23.5f, 23.5f, 5.5f, 2.2f, 8, frame); break;
        case "busy": Ring(g, 16, 16, 11, 3.2f, 12, frame); g.FillRectangle(new SolidBrush(MAG), 15, 15, 2, 2); break;
        case "cross": Neon(g, Lines(16,3,16,12, 16,20,16,29, 3,16,12,16, 20,16,29,16), false, CYAN, MAG); g.FillRectangle(new SolidBrush(MAG), 15, 15, 2, 2); break;
        case "ibeam": Neon(g, Lines(12,5,20,5, 16,5,16,27, 12,27,20,27), false, CYAN, MAG); break;
        case "pen": Neon(g, Poly(3,3, 10,5, 29,24, 24,29, 5,10), true, VIO, CYAN); g.DrawLine(P(MAG, 1.2f), 6, 6, 9, 9); break;
        case "no": var c = new GraphicsPath(); c.AddEllipse(5, 5, 22, 22); c.StartFigure(); c.AddLine(9, 23, 23, 9);
          g.DrawPath(P(Color.FromArgb(60, RED), 6f), c); g.DrawPath(P(DARK, 4.5f), c); g.DrawPath(P(RED, 2.4f), c); break;
        case "ns": Neon(g, Rot(DoubleArrow(), 90), true, CYAN, MAG); break;
        case "we": Neon(g, DoubleArrow(), true, CYAN, MAG); break;
        case "nwse": Neon(g, Rot(DoubleArrow(), 45), true, CYAN, MAG); break;
        case "nesw": Neon(g, Rot(DoubleArrow(), -45), true, CYAN, MAG); break;
        case "move": Neon(g, Poly(16,1, 21,6, 18,6, 18,14, 26,14, 26,11, 31,16, 26,21, 26,18, 18,18, 18,26, 21,26, 16,31, 11,26, 14,26, 14,18, 6,18, 6,21, 1,16, 6,11, 6,14, 14,14, 14,6, 11,6), true, CYAN, MAG); break;
        case "up": Neon(g, Poly(16,2, 24,11, 18,11, 18,30, 14,30, 14,11, 8,11), true, CYAN, MAG); break;
        case "link": Neon(g, Poly(11,3, 13,1, 15,3, 15,11, 19,11, 19,12, 23,12, 23,13, 27,13, 28,15, 28,24, 25,30, 14,30, 6,21, 7,18, 11,20), true, MAG, CYAN);
          g.DrawPath(P(MAG, 1f), Lines(19,12,19,18, 23,13,23,18)); break;
        case "pin": Neon(g, Arrow(), true, CYAN, MAG); Neon(g, Poly(23,13, 28,19, 23,30, 18,19), true, MAG, CYAN); g.FillEllipse(new SolidBrush(CYAN), 22, 18, 2, 2); break;
        case "person": Neon(g, Arrow(), true, CYAN, MAG);
          var pp = new GraphicsPath(); pp.AddEllipse(20, 12, 6, 6); pp.StartFigure(); pp.AddPolygon(new PointF[] { new PointF(17,29), new PointF(18,21), new PointF(28,21), new PointF(29,29) });
          Neon(g, pp, true, MAG, CYAN); break;
      }
    }
    return bmp;
  }

  static byte[] Dib(Bitmap b) {
    int w = b.Width, h = b.Height, maskStride = ((w + 31) / 32) * 4;
    var ms = new MemoryStream(); var bw = new BinaryWriter(ms);
    bw.Write(40); bw.Write(w); bw.Write(h * 2); bw.Write((short)1); bw.Write((short)32); bw.Write(0); bw.Write(w * h * 4 + maskStride * h); bw.Write(0); bw.Write(0); bw.Write(0); bw.Write(0);
    var mask = new byte[maskStride * h];
    for (int y = h - 1; y >= 0; y--) for (int x = 0; x < w; x++) {
      Color c = b.GetPixel(x, y); bw.Write(c.B); bw.Write(c.G); bw.Write(c.R); bw.Write(c.A);
      if (c.A == 0) mask[(h - 1 - y) * maskStride + x / 8] |= (byte)(0x80 >> (x % 8));
    }
    bw.Write(mask); return ms.ToArray();
  }

  // .cur file holding every size; hotspot given in 32-unit space.
  public static byte[] CurFile(string kind, int frame, float hx, float hy) {
    var imgs = new List<byte[]>(); foreach (int s in Sizes) using (var b = Render(kind, s, frame)) imgs.Add(Dib(b));
    var ms = new MemoryStream(); var bw = new BinaryWriter(ms);
    bw.Write((short)0); bw.Write((short)2); bw.Write((short)Sizes.Length);
    int off = 6 + 16 * Sizes.Length;
    for (int i = 0; i < Sizes.Length; i++) { int s = Sizes[i];
      bw.Write((byte)s); bw.Write((byte)s); bw.Write((byte)0); bw.Write((byte)0);
      bw.Write((short)Math.Round(hx * s / 32f)); bw.Write((short)Math.Round(hy * s / 32f)); bw.Write(imgs[i].Length); bw.Write(off); off += imgs[i].Length; }
    foreach (var d in imgs) bw.Write(d);
    return ms.ToArray();
  }

  public static void WriteAni(string path, string kind, int frames, int jiffies, float hx, float hy) {
    var fram = new MemoryStream(); var fw = new BinaryWriter(fram);
    fw.Write(System.Text.Encoding.ASCII.GetBytes("fram"));
    for (int f = 0; f < frames; f++) { var c = CurFile(kind, f, hx, hy);
      fw.Write(System.Text.Encoding.ASCII.GetBytes("icon")); fw.Write(c.Length); fw.Write(c); if (c.Length % 2 == 1) fw.Write((byte)0); }
    var body = new MemoryStream(); var w = new BinaryWriter(body);
    w.Write(System.Text.Encoding.ASCII.GetBytes("ACON"));
    w.Write(System.Text.Encoding.ASCII.GetBytes("anih")); w.Write(36);
    w.Write(36); w.Write(frames); w.Write(frames); w.Write(0); w.Write(0); w.Write(0); w.Write(0); w.Write(jiffies); w.Write(1);
    w.Write(System.Text.Encoding.ASCII.GetBytes("LIST")); w.Write((int)fram.Length); w.Write(fram.ToArray());
    var file = new MemoryStream(); var o = new BinaryWriter(file);
    o.Write(System.Text.Encoding.ASCII.GetBytes("RIFF")); o.Write((int)body.Length); o.Write(body.ToArray());
    File.WriteAllBytes(path, file.ToArray());
  }
}
"@

# role -> file, kind, hotspot (32-unit space); order matches the registry scheme string
$set = @(
  @('Arrow','RAVYN_Arrow.cur','arrow',3,3), @('Help','RAVYN_Help.cur','help',3,3), @('AppStarting','RAVYN_Working.ani','working',3,3),
  @('Wait','RAVYN_Busy.ani','busy',16,16), @('Crosshair','RAVYN_Cross.cur','cross',16,16), @('IBeam','RAVYN_Text.cur','ibeam',16,16),
  @('NWPen','RAVYN_Pen.cur','pen',3,3), @('No','RAVYN_No.cur','no',16,16), @('SizeNS','RAVYN_SizeNS.cur','ns',16,16),
  @('SizeWE','RAVYN_SizeWE.cur','we',16,16), @('SizeNWSE','RAVYN_SizeNWSE.cur','nwse',16,16), @('SizeNESW','RAVYN_SizeNESW.cur','nesw',16,16),
  @('SizeAll','RAVYN_Move.cur','move',16,16), @('UpArrow','RAVYN_Up.cur','up',16,2), @('Hand','RAVYN_Link.cur','link',13,1),
  @('Pin','RAVYN_Pin.cur','pin',3,3), @('Person','RAVYN_Person.cur','person',3,3)
)
foreach ($r in $set) {
  $p = Join-Path $Out $r[1]
  if ($r[1] -like '*.ani') { $n = if ($r[2] -eq 'busy') { 12 } else { 8 }; [Cur]::WriteAni($p, $r[2], $n, 4, $r[3], $r[4]) }
  else { [IO.File]::WriteAllBytes($p, [Cur]::CurFile($r[2], 0, $r[3], $r[4])) }
}

# Self-check: every file loads as a real Windows cursor.
Add-Type -Namespace U -Name N -MemberDefinition '[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr LoadCursorFromFile(string f);'
$bad = $set | Where-Object { [U.N]::LoadCursorFromFile((Join-Path $Out $_[1])) -eq [IntPtr]::Zero }
if ($bad) { throw "Cursor files failed to load: $($bad | ForEach-Object { $_[1] })" }

# Preview sheet: each cursor at 64px on dark and light tiles, plus busy-spinner frames.
$cell = 96; $sheet = New-Object Drawing.Bitmap ($cell * 9), ($cell * 5)
$g = [Drawing.Graphics]::FromImage($sheet); $g.Clear([Drawing.Color]::FromArgb(10,10,18))
$font = New-Object Drawing.Font 'Cascadia Code', 7
for ($i = 0; $i -lt $set.Count; $i++) {
  $col = $i % 9; $row = [math]::Floor($i / 9) * 2
  foreach ($k in 0, 1) {
    $x = $col * $cell; $y = ($row + $k) * $cell
    if ($k -eq 1) { $g.FillRectangle([Drawing.Brushes]::WhiteSmoke, $x, $y, $cell, $cell) }
    $b = [Cur]::Render($set[$i][2], 64, 0); $g.DrawImage($b, $x + 16, $y + 8); $b.Dispose()
    $g.DrawString($set[$i][0], $font, $(if ($k) { [Drawing.Brushes]::Black } else { [Drawing.Brushes]::Cyan }), $x + 4, $y + $cell - 14)
  }
}
for ($f = 0; $f -lt 9; $f++) { $b = [Cur]::Render('busy', 64, $f); $g.DrawImage($b, $f * $cell + 16, 4 * $cell + 8); $b.Dispose() }
$sheet.Save((Join-Path $Out 'preview.png'), [Drawing.Imaging.ImageFormat]::Png)
"OK: $($set.Count) cursors written to $Out"
