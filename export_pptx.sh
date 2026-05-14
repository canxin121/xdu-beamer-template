#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$root_dir"

input="${1:-}"
output="${2:-}"
preview_dpi="200"

if [[ -z "$input" ]]; then
  echo "Usage: $0 <input.tex|input.pdf> [output.pptx]" >&2
  echo "Note:  Export a PPTX whose slides use SVG artwork for crisp zooming." >&2
  echo "Note:  The PPTX is still page-as-image, not native editable text boxes." >&2
  exit 2
fi

base_pptx="$root_dir/pptx_base.pptx"
if [[ ! -f "$base_pptx" ]]; then
  echo "Error: missing base PPTX: $base_pptx" >&2
  exit 1
fi

pdf="$input"
if [[ "$input" == *.tex ]]; then
  ./build.sh "$input"
  base="$(basename "$input" .tex)"
  pdf="build/${base}.pdf"
fi

if [[ ! -f "$pdf" ]]; then
  echo "Error: PDF not found: $pdf" >&2
  exit 1
fi

for bin in pdftoppm unzip zip sed sort; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Error: missing required tool: $bin" >&2
    exit 1
  fi
done

if ! command -v pdftocairo >/dev/null 2>&1; then
  echo "Error: missing required tool: pdftocairo" >&2
  echo "Hint:  install poppler-utils (Linux) or poppler (Homebrew)." >&2
  exit 1
fi

tmp_img_dir="$(mktemp -d -t xdu_beamer_pdfpng_XXXXXX)"
tmp_pptx_dir="$(mktemp -d -t xdu_beamer_pptxdir_XXXXXX)"
cleanup() {
  rm -r "$tmp_img_dir" "$tmp_pptx_dir" 2>/dev/null || true
}
trap cleanup EXIT

pdftoppm -png -r "$preview_dpi" "$pdf" "$tmp_img_dir/slide" >/dev/null 2>&1
mapfile -t preview_images < <(ls "$tmp_img_dir"/slide-*.png 2>/dev/null | sort -t- -k2,2n)
num_slides="${#preview_images[@]}"
if [[ "$num_slides" -le 0 ]]; then
  echo "Error: failed to generate preview images from PDF: $pdf" >&2
  exit 1
fi

svg_files=()
for i in $(seq 1 "$num_slides"); do
  svg_path="$tmp_img_dir/slide-${i}.svg"
  pdftocairo -svg -f "$i" -l "$i" "$pdf" "$svg_path" >/dev/null 2>&1
  if [[ ! -s "$svg_path" ]]; then
    echo "Error: failed to generate SVG for page ${i}: $svg_path" >&2
    exit 1
  fi
  svg_files+=("$svg_path")
done

if [[ -z "$output" ]]; then
  mkdir -p dist
  output="dist/$(basename "${pdf%.pdf}").pptx"
else
  mkdir -p "$(dirname "$output")"
fi
if [[ "$output" == /* ]]; then
  output_abs="$output"
else
  output_abs="$root_dir/$output"
fi

unzip -q "$base_pptx" -d "$tmp_pptx_dir"

rm -f "$tmp_pptx_dir"/ppt/slides/slide*.xml
rm -f "$tmp_pptx_dir"/ppt/slides/_rels/slide*.xml.rels
rm -f "$tmp_pptx_dir"/ppt/media/image*.png
rm -f "$tmp_pptx_dir"/ppt/media/image*.svg
mkdir -p "$tmp_pptx_dir/ppt/slides/_rels" "$tmp_pptx_dir/ppt/media"

for i in $(seq 1 "$num_slides"); do
  cp "${preview_images[$((i - 1))]}" "$tmp_pptx_dir/ppt/media/image${i}.png"
  cp "${svg_files[$((i - 1))]}" "$tmp_pptx_dir/ppt/media/image${i}.svg"
done

slide_w="12192000"
slide_h="6858000"
for i in $(seq 1 "$num_slides"); do
  blip_xml="<a:blip r:embed=\"rId2\"><a:extLst><a:ext uri=\"{28A0092B-C50C-407E-A947-70E740481C1C}\"><a14:useLocalDpi xmlns:a14=\"http://schemas.microsoft.com/office/drawing/2010/main\" val=\"0\"/></a:ext><a:ext uri=\"{96DAC541-7B7A-43D3-8B79-37D633B846F1}\"><asvg:svgBlip xmlns:asvg=\"http://schemas.microsoft.com/office/drawing/2016/SVG/main\" r:embed=\"rId3\"/></a:ext></a:extLst></a:blip>"

  cat >"$tmp_pptx_dir/ppt/slides/slide${i}.xml" <<EOF
<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/><p:pic><p:nvPicPr><p:cNvPr id="2" name="Picture 1" descr="slide-${i}.png"/><p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr><p:blipFill>${blip_xml}<a:stretch><a:fillRect/></a:stretch></p:blipFill><p:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="${slide_w}" cy="${slide_h}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr></p:pic></p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>
EOF

  cat >"$tmp_pptx_dir/ppt/slides/_rels/slide${i}.xml.rels" <<EOF
<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout7.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/image${i}.png"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/image${i}.svg"/></Relationships>
EOF
done

sld_id_list=""
for i in $(seq 1 "$num_slides"); do
  slide_id=$((255 + i))
  rel_id=$((6 + i))
  sld_id_list="${sld_id_list}<p:sldId id=\"${slide_id}\" r:id=\"rId${rel_id}\"/>"
done

sed -E "s#<p:sldIdLst>.*</p:sldIdLst>#<p:sldIdLst>${sld_id_list}</p:sldIdLst>#" \
  "$tmp_pptx_dir/ppt/presentation.xml" >"$tmp_pptx_dir/ppt/presentation.xml.tmp"
mv "$tmp_pptx_dir/ppt/presentation.xml.tmp" "$tmp_pptx_dir/ppt/presentation.xml"

sed -E "s#type=\"screen4x3\"#type=\"screen16x9\"#g" \
  "$tmp_pptx_dir/ppt/presentation.xml" >"$tmp_pptx_dir/ppt/presentation.xml.tmp"
mv "$tmp_pptx_dir/ppt/presentation.xml.tmp" "$tmp_pptx_dir/ppt/presentation.xml"

{
  echo "<?xml version='1.0' encoding='UTF-8' standalone='yes'?>"
  echo "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
  echo "  <Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster\" Target=\"slideMasters/slideMaster1.xml\"/>"
  echo "  <Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/printerSettings\" Target=\"printerSettings/printerSettings1.bin\"/>"
  echo "  <Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/presProps\" Target=\"presProps.xml\"/>"
  echo "  <Relationship Id=\"rId4\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/viewProps\" Target=\"viewProps.xml\"/>"
  echo "  <Relationship Id=\"rId5\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme\" Target=\"theme/theme1.xml\"/>"
  echo "  <Relationship Id=\"rId6\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/tableStyles\" Target=\"tableStyles.xml\"/>"
  for i in $(seq 1 "$num_slides"); do
    rel_id=$((6 + i))
    echo "  <Relationship Id=\"rId${rel_id}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide\" Target=\"slides/slide${i}.xml\"/>"
  done
  echo "</Relationships>"
} >"$tmp_pptx_dir/ppt/_rels/presentation.xml.rels"

insert=""
for i in $(seq 2 "$num_slides"); do
  insert="${insert}<Override PartName=\"/ppt/slides/slide${i}.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.presentationml.slide+xml\"/>"
done

if [[ -n "$insert" ]]; then
  sed "s#</Types>#${insert}</Types>#" \
    "$tmp_pptx_dir/[Content_Types].xml" >"$tmp_pptx_dir/[Content_Types].xml.tmp"
  mv "$tmp_pptx_dir/[Content_Types].xml.tmp" "$tmp_pptx_dir/[Content_Types].xml"
fi

if ! grep -q 'Extension="png"' "$tmp_pptx_dir/[Content_Types].xml"; then
  sed 's#<Default Extension="jpeg" ContentType="image/jpeg"/>#<Default Extension="jpeg" ContentType="image/jpeg"/><Default Extension="png" ContentType="image/png"/>#' \
    "$tmp_pptx_dir/[Content_Types].xml" >"$tmp_pptx_dir/[Content_Types].xml.tmp"
  mv "$tmp_pptx_dir/[Content_Types].xml.tmp" "$tmp_pptx_dir/[Content_Types].xml"
fi

if ! grep -q 'Extension="svg"' "$tmp_pptx_dir/[Content_Types].xml"; then
  sed 's#<Default Extension="png" ContentType="image/png"/>#<Default Extension="png" ContentType="image/png"/><Default Extension="svg" ContentType="image/svg+xml"/>#' \
    "$tmp_pptx_dir/[Content_Types].xml" >"$tmp_pptx_dir/[Content_Types].xml.tmp"
  mv "$tmp_pptx_dir/[Content_Types].xml.tmp" "$tmp_pptx_dir/[Content_Types].xml"
fi

if [[ -f "$tmp_pptx_dir/docProps/app.xml" ]]; then
  sed -E "s#<Slides>[0-9]+</Slides>#<Slides>${num_slides}</Slides>#g" \
    "$tmp_pptx_dir/docProps/app.xml" >"$tmp_pptx_dir/docProps/app.xml.tmp"
  mv "$tmp_pptx_dir/docProps/app.xml.tmp" "$tmp_pptx_dir/docProps/app.xml"

  sed -E "s#On-screen Show \\(4:3\\)#On-screen Show (16:9)#g" \
    "$tmp_pptx_dir/docProps/app.xml" >"$tmp_pptx_dir/docProps/app.xml.tmp"
  mv "$tmp_pptx_dir/docProps/app.xml.tmp" "$tmp_pptx_dir/docProps/app.xml"
fi

rm -f "$output_abs"
(cd "$tmp_pptx_dir" && zip -q -r "$output_abs" .)

echo "$output_abs"
