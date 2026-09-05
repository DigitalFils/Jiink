/**
 * A minimal in-memory stand-in for the slice of the Firestore Admin SDK our
 * functions actually call (collection/doc get+set, a single-field `where`
 * query, and `runTransaction`). Not a Firestore emulator — no real
 * transactional isolation, only enough behavior to exercise our own logic
 * without the weight of spinning up the emulator in every test run.
 */

type DocData = Record<string, unknown>;

function deepMerge(target: DocData, patch: DocData): DocData {
  const result: DocData = { ...target };
  for (const [key, value] of Object.entries(patch)) {
    if (
      value !== null &&
      typeof value === "object" &&
      !Array.isArray(value) &&
      !(value instanceof Date) &&
      typeof result[key] === "object" &&
      result[key] !== null &&
      !Array.isArray(result[key])
    ) {
      result[key] = deepMerge(result[key] as DocData, value as DocData);
    } else {
      result[key] = value;
    }
  }
  return result;
}

export class FakeDocRef {
  constructor(
    private readonly store: Map<string, DocData>,
    public readonly path: string
  ) {}

  async get() {
    const data = this.store.get(this.path);
    return {
      exists: data !== undefined,
      data: () => data,
      ref: this,
    };
  }

  async set(data: DocData, opts?: { merge?: boolean }) {
    if (opts?.merge) {
      const existing = this.store.get(this.path) ?? {};
      this.store.set(this.path, deepMerge(existing, data));
    } else {
      this.store.set(this.path, data);
    }
  }
}

class FakeQuery {
  constructor(
    private readonly store: Map<string, DocData>,
    private readonly collectionName: string,
    private readonly field: string,
    private readonly value: unknown,
    private readonly limitCount = Infinity
  ) {}

  limit(count: number) {
    return new FakeQuery(this.store, this.collectionName, this.field, this.value, count);
  }

  async get() {
    const prefix = `${this.collectionName}/`;
    const docs = [...this.store.entries()]
      .filter(([path, data]) => path.startsWith(prefix) && data[this.field] === this.value)
      .slice(0, this.limitCount)
      .map(([path, data]) => ({
        data: () => data,
        ref: new FakeDocRef(this.store, path),
      }));
    return { empty: docs.length === 0, docs };
  }
}

class FakeCollectionRef {
  constructor(
    private readonly store: Map<string, DocData>,
    private readonly name: string
  ) {}

  doc(id: string) {
    return new FakeDocRef(this.store, `${this.name}/${id}`);
  }

  where(field: string, _op: string, value: unknown) {
    return new FakeQuery(this.store, this.name, field, value);
  }

  /** Every direct document in this collection — not documents nested one
   * more level down in some subcollection. */
  async get() {
    const prefix = `${this.name}/`;
    const docs = [...this.store.entries()]
      .filter(([path]) => path.startsWith(prefix) && !path.slice(prefix.length).includes("/"))
      .map(([path, data]) => ({
        data: () => data,
        ref: new FakeDocRef(this.store, path),
      }));
    return { empty: docs.length === 0, docs };
  }
}

export class FakeFirestore {
  readonly store = new Map<string, DocData>();

  collection(name: string) {
    return new FakeCollectionRef(this.store, name);
  }

  /** Seeds a document directly, bypassing merge semantics — for test setup. */
  seed(path: string, data: DocData) {
    this.store.set(path, data);
  }

  async runTransaction<T>(
    fn: (tx: { get: FakeDocRef["get"]; set: FakeDocRef["set"] }) => Promise<T>
  ): Promise<T> {
    const tx = {
      get: (ref: FakeDocRef) => ref.get(),
      set: (ref: FakeDocRef, data: DocData, opts?: { merge?: boolean }) => ref.set(data, opts),
    };
    return fn(tx as never);
  }
}
