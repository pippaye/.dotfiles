{
  pkgs,
  config,
  lib,
  isLinux,
  ...
}:
let
  python = pkgs.python3.withPackages (
    ps:
    with ps;
    [
      # 基础
      ipython
      rich
      typer
      click
      pydantic
      python-dotenv
      loguru
      tqdm

      # 数据处理
      numpy
      pandas
      polars
      pyarrow
      duckdb
      sqlalchemy

      # Excel / CSV / 表格
      openpyxl
      xlsxwriter
      xlrd
      odfpy
      tabulate

      # Word / PPT
      python-docx
      python-pptx

      # PDF
      pypdf
      pymupdf
      pdfplumber
      reportlab

      # Web 请求 / 抓取
      requests
      httpx
      aiohttp
      beautifulsoup4
      lxml
      feedparser

      # 图像处理 / OCR 前处理
      pillow
      qrcode

      # 文本 / 格式
      pyyaml
      tomlkit
      markdown
      beautifulsoup4
      jinja2

      # 时间 / 文件 / 系统
      python-dateutil
      pytz
      platformdirs
      watchdog
      pathspec

      # 压缩 / 归档 / 文件识别
      python-magic
      send2trash

      # 测试和脚本质量
      pytest
      ruff
      black
    ]
    ++ lib.optionals isLinux [
      imageio
    ]
  );
  cfg = config.hmProfiles.dev;
in
{
  home.packages = lib.optionals (!cfg.lite) [
    python
  ];
}
