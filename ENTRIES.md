# Entries — What They Are

An **entry** is a single conceptual creative work — the art itself, not a product you buy or a season within it.

**The test:** Can you point to it and say "that's a complete work"? If yes, it's an entry.

---

## Entry Rules by Medium

| Medium | What counts as ONE entry | Notes |
|--------|--------------------------|-------|
| **Anime (TV series)** | The entire serialized show (all seasons) | Seasons go in `entry_seasons`. AniList/MAL split by season — we consolidate. |
| **Anime (Movie)** | Each movie | Even if it's a direct continuation (e.g., Mugen Train) |
| **Anime (OVA)** | Each standalone OVA | Some OVAs are a few episodes — still one entry |
| **Manga** | The entire serialized run (all volumes/chapters) | Berserk = one entry. Individual volumes are products. |
| **Light Novel** | The entire serialized run | Same as manga |
| **Novel** | Each book | Harry Potter 1, Harry Potter 2 = separate entries |
| **Movie (Hollywood)** | Each movie | The Dark Knight, The Dark Knight Rises = separate entries |
| **TV Show (Hollywood)** | The entire serialized show (all seasons) | Breaking Bad = one entry. Seasons in `entry_seasons`. |
| **Video Game** | Each game | Elden Ring, Dark Souls 3 = separate entries. DLC = product-level. |
| **Music Album** | Each album or EP | Tracks belong to the entry. |
| **Board Game** | Each game | Expansions TBD (product-level or separate entry?) |

---

## Spin-offs Are Separate Entries

A spin-off is a **new work** — it gets its own entry, not a season of the parent.

The distinction: Is it the same show continuing, or a different show in the same universe?

- **Same show continuing** → season of the entry
- **Different show, same universe** → separate entry

---

## Example: KonoSuba

**Franchise:** KonoSuba: God's Blessing on This Wonderful World!

| Entry | Medium | Reasoning |
|-------|--------|-----------|
| KonoSuba (light novel) | light-novel | The source material. All 17 volumes = ONE entry |
| KonoSuba (manga) | manga | Main manga adaptation. ONE entry |
| KonoSuba (anime) | anime-series | S1, S2, S3 = ONE entry. Seasons in `entry_seasons` |
| KonoSuba: Legend of Crimson | anime-movie | The 2019 film. SEPARATE entry |
| KonoSuba: An Explosion on This Wonderful World! | anime-series | Megumin spin-off anime. SEPARATE entry — different show |
| Megumin Explosion (light novel) | light-novel | Spin-off LN series. SEPARATE entry |
| Konosuba: Fantastic Days | game | Mobile game. SEPARATE entry |

---

## Example: Attack on Titan

**Franchise:** Attack on Titan

| Entry | Medium | Reasoning |
|-------|--------|-----------|
| Attack on Titan (manga) | manga | All 34 volumes = ONE entry |
| Attack on Titan (anime) | anime-series | S1-S4 + Final Chapters = ONE entry. Seasons in `entry_seasons` |
| Attack on Titan: Junior High | anime-series | Parody spin-off. SEPARATE entry |
| Attack on Titan: No Regrets | manga | Levi spin-off manga. SEPARATE entry |
| Attack on Titan: Before the Fall | manga | Prequel manga. SEPARATE entry |

---

## Example: Fate

**Franchise:** Fate

| Entry | Medium | Reasoning |
|-------|--------|-----------|
| Fate/stay night (visual novel) | game | The source. ONE entry |
| Fate/stay night (2006 anime) | anime-series | DEEN adaptation. ONE entry |
| Fate/stay night: Unlimited Blade Works | anime-series | ufotable adaptation. SEPARATE entry (different route) |
| Fate/stay night: Heaven's Feel | anime-movie | Three films. Could be ONE entry or three — TBD |
| Fate/Zero | anime-series | Prequel. SEPARATE entry |
| Fate/Apocrypha | anime-series | Alt universe. SEPARATE entry |
| Fate/Grand Order | game | Mobile game. SEPARATE entry |
| Fate/Grand Order: Babylonia | anime-series | Anime adaptation of FGO arc. SEPARATE entry |

---

## Not Entries

These are **not** entries:

- A Blu-ray box set → **product** (linked to an entry)
- Season 2 → lives in **entry_seasons**
- A figure of Eren → **product** (linked to character + entry)
- Episode 5 → lives in **season_episodes**
- The Japanese pressing of an album → **product** (variant of the entry)

---

## The Hierarchy

```
Franchise (IP umbrella — "Attack on Titan")
  └── Entry (conceptual work — "Attack on Titan anime")
       ├── entry_seasons (S1, S2, S3, S4)
       │    └── season_episodes (eps 1-25, etc.)
       └── Products (Blu-rays, figures, etc.)
```

Characters, Companies (studios), and Creators (staff/VAs) exist **across** entries and franchises.
