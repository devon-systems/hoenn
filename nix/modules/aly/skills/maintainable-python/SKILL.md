---
name: maintainable-python
description: Use when writing, refactoring, or reviewing Python code, especially data models, type annotations, input validation, and module design.
---

# Write maintainable Python

Follow the project's supported Python version, dependencies, and tools.

## Reuse existing definitions first

Before adding a type, model, validator, or parser, search by concept, field names, and constraints.
Check shared modules and nearby callers. Read candidate definitions and their validation rules.
Reuse the smallest matching definition, such as an `Annotated` constraint, enum, value type, or parser.
Share those definitions even when input, domain, persistence, and response models need separate contracts.
Reuse a whole model only when its meaning and rules should change together for all callers.
Similar field names alone do not justify sharing a model.

## Write typed functions and models

Annotate all function and method parameters, return values, and model fields, including helpers and `-> None`.
Specify collection element types and possible `None` results. Let precise local types use inference.
Validate or narrow `Any` from integrations before application code uses it.
Use `object` for unknown values that require inspection before use.

Use built-in collection types, `T | None`, and generic syntax supported by the project.
Accept `Iterable[T]`, `Sequence[T]`, or `Mapping[K, V]` when those operations suffice.
Return concrete collections when callers need complete, reusable results.
Use type parameters to preserve input-output relationships, and `Protocol` for shared required operations.
For decorators, preserve signatures with `ParamSpec` and a return type parameter, and metadata with `functools.wraps`.

Fix type errors where they originate. Avoid broad unions that hide incompatible caller expectations.
Keep casts and suppressions narrow and explain their assumptions.
Annotations, aliases, and casts do not validate runtime values, including dataclass fields.

## Choose types that express the data

- Use dataclasses for named records, or `NamedTuple` when tuple compatibility matters.
  Use plain classes when behavior or resource management dominates the fields.
- Use `Literal["json", "csv"]` for fixed choices of ordinary strings. Name reused unions with a type alias.
- Use enums for named runtime members, iteration, or lookup by value.
  Choose `StrEnum` for string interoperability and plain `Enum` for distinct domain members.
  Define stored or transmitted values explicitly rather than with `auto()`.
- Use unions of records when alternatives require different fields.
  Narrow variants with `isinstance` or literal discriminator fields, and check exhaustive handling.
- Use the project's validation approach. Choose Pydantic when runtime input validation or schema generation justifies it.
  Do not add it merely to serialize a simple internal record.
- Use `TypedDict` for fixed dictionary shapes and ordinary dictionaries when keys are data.
- Use value types or `NewType` when they prevent meaningful mistakes, such as swapping unrelated IDs.
- Give `None` one meaning per API. Distinguish omitted updates from explicit clears with a sentinel or separate alternatives.

Avoid a class for every string or a state union when one optional field expresses the requirement.
Read the relevant section of [type-choice examples](references/examples.md) for concrete bad and good cases.
Adapt their Python 3.12 syntax to the project's version.

## Configure dataclasses deliberately

- Prefer `frozen=True` for stable values and snapshots. Freezing is shallow, so use immutable contents when needed.
- Use `kw_only=True` when positional arguments would be easy to confuse.
- Use `slots=True` when memory savings or attribute restrictions help. Check for dependencies on instance `__dict__`.
- Use `field(default_factory=...)` for per-instance mutable defaults.
- Keep field-based equality for values. Use `eq=False` to retain inherited equality, usually object identity.
  Implement equality by domain ID explicitly when needed. Changes to hashed fields can break set and dictionary lookups.
  Avoid `unsafe_hash=True` as a workaround for mutable records.
- Put value checks and relationships between fields in `__post_init__`.
- Compute derived values with properties. Store historical values when recalculation would change their meaning.

## Validate external input with Pydantic v2

Use built-in field types and `Annotated` with `Field` constraints before custom validators.
Use field validators for individual values and model validators for relationships between fields.

Choose validation policies explicitly:

- Use strict validation when accepting another type would hide a mistake. Allow conversion when the format requires it.
  Check the relevant types because strict Python and JSON validation can differ.
- Use `extra="forbid"` when unknown or misspelled fields should fail.
- Distinguish nullable fields from defaults. `T | None` alone does not make a field optional to supply.
- Use `TypeAdapter` to validate existing types or collections without another model.
- Use discriminated unions when parsing tagged variants.
- Use model validation and serialization APIs instead of handwritten field maps.
  Use `validation_alias` and `serialization_alias` when input and output names differ.
- Treat `model_construct()` and `model_copy(update=...)` as trusted operations that bypass validation of supplied data.
- Enable assignment validation when mutable field changes must preserve validation rules.
  It does not catch in-place changes inside lists or dictionaries.
- For patch models, use `model_fields_set` to distinguish omission from an explicitly supplied `None`.

## Preserve behavior at Python boundaries

Keep errors that callers act on typed. Catch specific exceptions and preserve translated causes with `raise ... from error`.
Do not turn unexpected failures or cancellation into `None` or success.
Call constructors and library methods directly unless a helper adds domain meaning or policy.
Use context managers for resources and task groups for child tasks. Preserve cancellation and cleanup.
For large async workloads, bound queued work, task creation, and retained results as well as active operations.

Use `zip(..., strict=True)` when inputs must have equal lengths.
Preserve ordering, duplicates, and eager or lazy behavior when replacing manual code with library calls.
Use keyword arguments when booleans or adjacent arguments would otherwise make calls ambiguous.

Run the project's formatter, linter, type checker, and relevant tests.
For model changes, check invalid inputs, defaults, conversions, and update paths. Report which checks ran.
