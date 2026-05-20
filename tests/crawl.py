from html.parser import HTMLParser
from urllib import request


class GeekNewsCrawler:
    def __init__(self, url: str = "https://news.hada.io/", timeout_seconds: int = 10):
        self._url = url
        self._timeout_seconds = timeout_seconds

    def crawl(self) -> list[str]:
        html = self._fetch_html()
        return self._extract_titles(html)

    def _fetch_html(self) -> str:
        req = request.Request(
            self._url,
            headers={
                "User-Agent": "whatson-crawler-test/1.0",
                "Accept": "text/html,application/xhtml+xml",
            },
        )

        with request.urlopen(req, timeout=self._timeout_seconds) as response:
            charset = response.headers.get_content_charset() or "utf-8"
            return response.read().decode(charset, errors="replace")

    def _extract_titles(self, html: str) -> list[str]:
        parser = _TopicTitleParser()
        parser.feed(html)
        parser.close()
        return parser.titles


class _TopicTitleParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.titles: list[str] = []
        self._inside_target = False
        self._target_depth = 0
        self._chunks: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if self._inside_target:
            self._target_depth += 1
            return

        if tag != "h2":
            return

        class_value = self._attr_value(attrs, "class")
        classes = class_value.split()
        if "topic-title-heading" not in classes:
            return

        self._inside_target = True
        self._target_depth = 0
        self._chunks = []

    def handle_endtag(self, tag: str) -> None:
        if not self._inside_target:
            return

        if self._target_depth > 0:
            self._target_depth -= 1
            return

        if tag == "h2":
            title = self._normalize_title("".join(self._chunks))
            if title:
                self.titles.append(title)
            self._inside_target = False
            self._chunks = []

    def handle_data(self, data: str) -> None:
        if self._inside_target:
            self._chunks.append(data)

    def _attr_value(self, attrs: list[tuple[str, str | None]], name: str) -> str:
        for attr_name, attr_value in attrs:
            if attr_name == name and attr_value:
                return attr_value
        return ""

    def _normalize_title(self, title: str) -> str:
        return " ".join(title.split())
