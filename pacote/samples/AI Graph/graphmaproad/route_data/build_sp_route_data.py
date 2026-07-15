from __future__ import annotations

import heapq
import json
import math
import unicodedata
from collections import defaultdict
from pathlib import Path

import requests

try:
    import duckdb
except ImportError:  # pragma: no cover - optional dependency for regeneration only
    duckdb = None


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "route_data" / "generated"
IBGE_MUNICIPALITIES_URL = "https://servicodados.ibge.gov.br/api/v1/localidades/estados/35/municipios"
IBGE_MALHAS_URL = "https://servicodados.ibge.gov.br/api/v4/malhas/estados/SP"
GEOBR_MUNICIPAL_SEATS_URL = "https://github.com/ipea/geobr_prep_data/releases/download/v2.0.0/municipalseats_2022.parquet"
USER_AGENT = "maurinsoft-graphmaproad-dataset-builder/1.0"


def normalize_text(value: str) -> str:
    value = unicodedata.normalize("NFKD", value or "")
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    return " ".join(value.lower().split())


def haversine_m(lon1: float, lat1: float, lon2: float, lat2: float) -> float:
    radius = 6371000.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)
    a = math.sin(d_phi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2.0) ** 2
    return 2.0 * radius * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))


def ring_area_and_centroid(ring: list[list[float]]) -> tuple[float, float, float]:
    if not ring:
        return 0.0, 0.0, 0.0

    points = [(float(p[0]), float(p[1])) for p in ring]
    if points[0] != points[-1]:
        points.append(points[0])

    area2 = 0.0
    cx = 0.0
    cy = 0.0
    for i in range(len(points) - 1):
        x1, y1 = points[i]
        x2, y2 = points[i + 1]
        cross = x1 * y2 - x2 * y1
        area2 += cross
        cx += (x1 + x2) * cross
        cy += (y1 + y2) * cross

    area = area2 / 2.0
    if abs(area) < 1e-12:
        avg_x = sum(p[0] for p in points[:-1]) / max(1, len(points) - 1)
        avg_y = sum(p[1] for p in points[:-1]) / max(1, len(points) - 1)
        return 0.0, avg_x, avg_y

    cx /= (3.0 * area2)
    cy /= (3.0 * area2)
    return abs(area), cx, cy


def geometry_centroid(geometry: dict) -> tuple[float, float]:
    gtype = geometry.get("type", "")
    coordinates = geometry.get("coordinates", [])

    if gtype == "Polygon":
        area, cx, cy = ring_area_and_centroid(coordinates[0] if coordinates else [])
        return cx, cy

    if gtype == "MultiPolygon":
        total_area = 0.0
        sum_x = 0.0
        sum_y = 0.0
        for polygon in coordinates:
            if not polygon:
                continue
            area, cx, cy = ring_area_and_centroid(polygon[0])
            if area <= 0:
                continue
            total_area += area
            sum_x += cx * area
            sum_y += cy * area
        if total_area > 0:
            return sum_x / total_area, sum_y / total_area

    points: list[tuple[float, float]] = []
    stack = [coordinates]
    while stack:
        item = stack.pop()
        if not item:
            continue
        if isinstance(item[0], (int, float)) and len(item) >= 2:
            points.append((float(item[0]), float(item[1])))
        else:
            stack.extend(item)
    if not points:
        raise ValueError("Geometry does not contain coordinates.")
    return (
        sum(p[0] for p in points) / len(points),
        sum(p[1] for p in points) / len(points),
    )


def road_type_for_distance(distance_m: float) -> str:
    if distance_m >= 220000:
        return "motorway"
    if distance_m >= 150000:
        return "trunk"
    if distance_m >= 100000:
        return "primary"
    if distance_m >= 70000:
        return "secondary"
    if distance_m >= 40000:
        return "tertiary"
    return "residential"


def max_speed_for_road_type(highway: str) -> int:
    return {
        "motorway": 110,
        "trunk": 100,
        "primary": 90,
        "secondary": 80,
        "tertiary": 70,
        "residential": 50,
    }.get(highway, 60)


def component_root(parent: dict[int, int], item: int) -> int:
    while parent[item] != item:
        parent[item] = parent[parent[item]]
        item = parent[item]
    return item


def union(parent: dict[int, int], rank: dict[int, int], a: int, b: int) -> bool:
    ra = component_root(parent, a)
    rb = component_root(parent, b)
    if ra == rb:
        return False
    if rank[ra] < rank[rb]:
        ra, rb = rb, ra
    parent[rb] = ra
    if rank[ra] == rank[rb]:
        rank[ra] += 1
    return True


def fetch_json(url: str, params: dict | None = None) -> object:
    response = requests.get(
        url,
        params=params,
        headers={"User-Agent": USER_AGENT, "Accept": "application/json, application/vnd.geo+json"},
        timeout=180,
    )
    response.raise_for_status()
    return response.json()


def fetch_binary(url: str) -> bytes:
    response = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=180)
    response.raise_for_status()
    return response.content


def parse_point_wkt(wkt: str) -> tuple[float, float]:
    text = (wkt or "").strip()
    if not text.upper().startswith("POINT"):
        raise ValueError(f"Unsupported WKT geometry: {wkt!r}")
    start = text.find("(")
    end = text.rfind(")")
    if start < 0 or end < 0 or end <= start:
        raise ValueError(f"Invalid WKT geometry: {wkt!r}")
    lon_text, lat_text = text[start + 1 : end].strip().split()
    return float(lon_text), float(lat_text)


def load_municipal_seats() -> dict[str, tuple[float, float]]:
    if duckdb is None:
        return {}

    cache_dir = DATA_DIR / "_cache"
    cache_dir.mkdir(parents=True, exist_ok=True)
    parquet_path = cache_dir / "municipalseats_2022.parquet"
    if not parquet_path.exists():
        parquet_path.write_bytes(fetch_binary(GEOBR_MUNICIPAL_SEATS_URL))

    query = f"""
        SELECT
            CAST(code_muni AS BIGINT) AS code_muni,
            ST_AsText(geometry) AS wkt
        FROM read_parquet('{parquet_path.as_posix()}')
        WHERE CAST(code_state AS BIGINT) = 35
    """
    rows = duckdb.query(query).fetchall()
    seats: dict[str, tuple[float, float]] = {}
    for code_muni, wkt in rows:
        try:
            seats[str(int(code_muni))] = parse_point_wkt(wkt)
        except Exception:
            continue
    return seats


def load_municipalities() -> list[dict]:
    municipalities = fetch_json(IBGE_MUNICIPALITIES_URL)
    if not isinstance(municipalities, list):
        raise RuntimeError("Municipalities API returned an unexpected payload.")

    name_by_code = {str(item["id"]): item["nome"] for item in municipalities}

    malhas = fetch_json(
        IBGE_MALHAS_URL,
        {
            "formato": "application/vnd.geo+json",
            "intrarregiao": "municipio",
            "qualidade": "maxima",
        },
    )
    if not isinstance(malhas, dict):
        raise RuntimeError("Malhas API returned an unexpected payload.")

    features = malhas.get("features", [])
    if len(features) != len(municipalities):
        raise RuntimeError(
            f"Expected {len(municipalities)} municipality features, got {len(features)}."
        )

    seats = load_municipal_seats()
    result = []
    for feature in features:
        props = feature.get("properties", {})
        code = str(props.get("codarea", "")).strip()
        if not code:
            continue
        if code not in name_by_code:
            raise RuntimeError(f"Could not find municipality name for code {code}.")
        lon, lat = seats.get(code, geometry_centroid(feature["geometry"]))
        result.append(
            {
                "code": code,
                "name": name_by_code[code],
                "longitude": lon,
                "latitude": lat,
            }
        )

    result.sort(key=lambda item: (normalize_text(item["name"]), item["code"]))
    return result


def build_knn_edges(nodes: list[dict], k: int = 4) -> list[dict]:
    node_count = len(nodes)
    node_index_by_code = {node["code"]: idx for idx, node in enumerate(nodes)}
    neighbors: dict[int, list[tuple[float, int]]] = {idx: [] for idx in range(node_count)}
    edge_keys: set[tuple[int, int]] = set()

    for i in range(node_count):
        node_i = nodes[i]
        for j in range(i + 1, node_count):
            node_j = nodes[j]
            dist = haversine_m(
                node_i["longitude"],
                node_i["latitude"],
                node_j["longitude"],
                node_j["latitude"],
            )
            heapq.heappush(neighbors[i], (-dist, j))
            heapq.heappush(neighbors[j], (-dist, i))
            if len(neighbors[i]) > k:
                heapq.heappop(neighbors[i])
            if len(neighbors[j]) > k:
                heapq.heappop(neighbors[j])

    edges = []
    edge_id = 1

    def add_edge(source_index: int, target_index: int) -> None:
        nonlocal edge_id
        a = nodes[source_index]
        b = nodes[target_index]
        key = (min(source_index, target_index), max(source_index, target_index))
        if key in edge_keys:
            return
        edge_keys.add(key)
        dist = haversine_m(a["longitude"], a["latitude"], b["longitude"], b["latitude"])
        highway = road_type_for_distance(dist)
        speed = max_speed_for_road_type(highway)
        edges.append(
            {
                "id": edge_id,
                "u": int(a["code"]),
                "v": int(b["code"]),
                "highway": highway,
                "name": f"Route between {a['name']} and {b['name']}",
                "ref": f"SP-{a['code']}-{b['code']}",
                "oneway": "false",
                "toll": "false",
                "maxspeed": str(speed),
                "length_m": round(dist, 2),
                "geometry": [
                    [a["longitude"], a["latitude"]],
                    [b["longitude"], b["latitude"]],
                ],
            }
        )
        edge_id += 1

    for i in range(node_count):
        nearest = sorted((-distance, index) for distance, index in neighbors[i])
        for _, j in nearest:
            add_edge(i, j)

    parent = {i: i for i in range(node_count)}
    rank = {i: 0 for i in range(node_count)}
    for edge in edges:
        union(parent, rank, node_index_by_code[str(edge["u"])], node_index_by_code[str(edge["v"])])

    components: dict[int, list[int]] = defaultdict(list)
    for idx in range(node_count):
        components[component_root(parent, idx)].append(idx)

    if len(components) > 1:
        anchors = list(components.values())
        base = anchors[0]
        for comp in anchors[1:]:
            best_pair = None
            best_dist = float("inf")
            for i in base:
                node_i = nodes[i]
                for j in comp:
                    node_j = nodes[j]
                    dist = haversine_m(
                        node_i["longitude"],
                        node_i["latitude"],
                        node_j["longitude"],
                        node_j["latitude"],
                    )
                    if dist < best_dist:
                        best_dist = dist
                        best_pair = (i, j)
            if best_pair is not None:
                add_edge(*best_pair)
                union(parent, rank, best_pair[0], best_pair[1])
                base.extend(comp)

    return edges


def feature_collection(features: list[dict]) -> dict:
    return {"type": "FeatureCollection", "features": features}


def build_node_features(nodes: list[dict]) -> list[dict]:
    features = []
    for node in nodes:
        features.append(
            {
                "type": "Feature",
                "properties": {
                    "id": int(node["code"]),
                    "name": node["name"],
                    "ibge_code": node["code"],
                    "state": "SP",
                },
                "geometry": {
                    "type": "Point",
                    "coordinates": [node["longitude"], node["latitude"]],
                },
            }
        )
    return features


def build_city_features(nodes: list[dict]) -> list[dict]:
    return [
        {
            "type": "Feature",
            "properties": {
                "ibge_code": node["code"],
                "name": node["name"],
                "state": "SP",
            },
            "geometry": {
                "type": "Point",
                "coordinates": [node["longitude"], node["latitude"]],
            },
        }
        for node in nodes
    ]


def build_edge_features(edges: list[dict]) -> list[dict]:
    features = []
    for edge in edges:
        features.append(
            {
                "type": "Feature",
                "properties": {
                    "id": edge["id"],
                    "u": edge["u"],
                    "v": edge["v"],
                    "highway": edge["highway"],
                    "name": edge["name"],
                    "ref": edge["ref"],
                    "oneway": edge["oneway"],
                    "toll": edge["toll"],
                    "maxspeed": edge["maxspeed"],
                    "length_m": edge["length_m"],
                },
                "geometry": {
                    "type": "LineString",
                    "coordinates": edge["geometry"],
                },
            }
        )
    return features


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> None:
    nodes = load_municipalities()
    edges = build_knn_edges(nodes, k=4)

    write_json(DATA_DIR / "sp_route_nodes.geojson", feature_collection(build_node_features(nodes)))
    write_json(DATA_DIR / "sp_cities.geojson", feature_collection(build_city_features(nodes)))
    write_json(DATA_DIR / "sp_route_edges.geojson", feature_collection(build_edge_features(edges)))
    write_json(
        DATA_DIR / "manifest.json",
        {
            "dataset": "Sao Paulo municipalities route graph",
            "source": "IBGE municipalities + IBGE malhas",
            "nodes": len(nodes),
            "edges": len(edges),
            "cities": len(nodes),
            "notes": [
                "The graph uses all 645 municipalities of Sao Paulo state.",
                "Nodes and cities use the municipality seat coordinates from geobr when available, with boundary centroids as fallback.",
                "Routes were generated as municipal connections so the sample stays visual and fully local.",
            ],
        },
    )
    print(f"Wrote {len(nodes)} nodes, {len(edges)} edges and {len(nodes)} cities to {DATA_DIR}.")


if __name__ == "__main__":
    main()
