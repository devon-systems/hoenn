# Why these type choices help

These examples use Python 3.12 or newer and Pydantic v2.
Each pair shows a defect and a representation that prevents it.

## Named records and explicit signatures

Bad. The function declares neither the record shape nor its input and result types.
A field typo or a wrongly typed flag can pass unnoticed by a type checker.

```python
def active_account_names(accounts):
	return [account["name"] for account in accounts if account["is_active"]]
```

Good. A snapshot record makes the fields explicit, and the signature declares the input and result types.

```python
from collections.abc import Iterable
from dataclasses import dataclass


@dataclass(frozen=True, kw_only=True)
class AccountSnapshot:
	name: str
	is_active: bool


def active_account_names(accounts: Iterable[AccountSnapshot]) -> list[str]:
	return [account.name for account in accounts if account.is_active]
```

The new representation requires changes to both producers and callers.
When an external API requires dictionaries, a `TypedDict` can preserve that format.

## Literal choices and runtime enum members

Bad. A misspelled direction silently selects ascending order.

```python
from collections.abc import Iterable


def sort_names(names: Iterable[str], direction: str) -> list[str]:
	return sorted(names, key=str.casefold, reverse=direction == "descending")
```

Good. `SortDirection` restricts the accepted strings for a function that sorts names without case sensitivity.
A type checker rejects `sort_names(["Ada"], "descendng")`.

```python
from collections.abc import Iterable
from typing import Literal

type SortDirection = Literal["ascending", "descending"]


def sort_names(names: Iterable[str], direction: SortDirection) -> list[str]:
	return sorted(names, key=str.casefold, reverse=direction == "descending")
```

An enum is appropriate when the application needs named runtime members or lookup by value:

```python
from enum import StrEnum


class SortDirection(StrEnum):
	ASCENDING = "ascending"
	DESCENDING = "descending"


direction = SortDirection("descending")
available_directions = tuple(SortDirection)
```

`SortDirection("descendng")` raises `ValueError`; an annotation alone performs no runtime check.
`StrEnum` members can compare equal to matching strings and members of unrelated `StrEnum` classes.
Plain `Enum` preserves separation. Both enums and literals support exhaustive type checking.

## States with different required fields

Bad. Even with annotations, this model permits a successful download with no path,
or a download marked both successful and failed.

```python
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Download:
	complete: bool = False
	failed: bool = False
	path: Path | None = None
	error: str | None = None
```

Good. Separate records give each state its required fields.
A successful download has a path, and a failed download has a typed reason and a message.

```python
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import assert_never


@dataclass(frozen=True)
class Pending:
	pass


@dataclass(frozen=True)
class Downloaded:
	path: Path


class DownloadFailureKind(Enum):
	TIMEOUT = "timeout"
	NOT_FOUND = "not_found"


@dataclass(frozen=True, kw_only=True)
class Failed:
	kind: DownloadFailureKind
	message: str


type Download = Pending | Downloaded | Failed


def describe_download(download: Download) -> str:
	if isinstance(download, Pending):
		return "Waiting"
	if isinstance(download, Downloaded):
		return str(download.path)
	if isinstance(download, Failed):
		return download.message
	assert_never(download)
```

The checker narrows each branch to the appropriate record.
Adding another union member makes the unhandled case a type error at `assert_never`.
Callers can branch on `Failed.kind`, such as retrying a timeout, without parsing the explanatory message.

## Runtime validation of external input

Bad. A cast tells the checker to trust decoded JSON without checking its shape or values.
This accepts a missing URL or a negative retry count.

```python
import json
from typing import TypedDict, cast


class DownloadRequest(TypedDict):
	url: str
	retries: int


def parse_request(raw: bytes) -> DownloadRequest:
	return cast(DownloadRequest, json.loads(raw))
```

Good. The Pydantic model defines the input fields, validation constraints, and default.

```python
from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


class DownloadRequest(BaseModel):
	model_config = ConfigDict(extra="forbid", frozen=True)

	url: HttpUrl
	retries: Annotated[int, Field(strict=True, ge=0, le=5)] = 3


request = DownloadRequest.model_validate_json(b'{"url": "https://example.com/report.csv"}')
```

The retry count accepts integers from zero through five and rejects strings and booleans.
An HTTP handler or CLI entry point can translate `ValidationError` into the appropriate response.

## Omitted updates and explicit clears

Both versions use this mutable record for an in-process update:

```python
from dataclasses import dataclass


@dataclass
class Profile:
	nickname: str | None
```

Bad. The default cannot distinguish "leave unchanged" from "clear the nickname."

```python
def update_nickname(profile: Profile, *, nickname: str | None = None) -> None:
	if nickname is not None:
		profile.nickname = nickname
```

Good. A sentinel represents omission, leaving `None` available for clearing the field.

```python
from enum import Enum


class UpdateAction(Enum):
	KEEP = "keep"


def update_nickname(
	profile: Profile, *, nickname: str | None | UpdateAction = UpdateAction.KEEP
) -> None:
	if nickname is UpdateAction.KEEP:
		return
	profile.nickname = nickname
```

`update_nickname(profile)` preserves the nickname, `nickname=None` clears it, and `nickname="Ada"` sets it.
For a Pydantic patch model, `model_fields_set` tracks supplied fields without adding a sentinel to the input format.
