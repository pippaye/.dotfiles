{
  pkgs,
  config,
  lib,
  isLinux,
  ...
}:
let
  pythonWithBeanqueryWorkaround = pkgs.python313.override {
    packageOverrides = python-final: python-prev: {
      beanquery = python-prev.beanquery.overridePythonAttrs (oldAttrs: {
        # TODO : beanquery installs a top-level site-packages/docs directory.
        # In this shared Python environment it conflicts with cryptography's docs
        # when fava and pdfplumber are both present. This docs directory is not
        # needed at runtime; revisit or remove this once nixpkgs/upstream package
        # metadata stops installing it into site-packages.
        postInstall = (oldAttrs.postInstall or "") + ''
          rm -rf $out/${python-final.python.sitePackages}/docs
        '';
      });
      # FIXIT
      pandas-stubs = python-prev.pandas-stubs.overridePythonAttrs (_: {
        # This is a type-stub package; nixpkgs incorrectly checks `import pandas`
        # without adding pandas as a runtime dependency.
        pythonImportsCheck = [ ];
        # The current pandas/NumPy dependency set is incompatible with its test suite.
        doCheck = false;
      });
    };
  };
  python = pythonWithBeanqueryWorkaround.withPackages (
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
      matplotlib

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

      beancount
      fava
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
