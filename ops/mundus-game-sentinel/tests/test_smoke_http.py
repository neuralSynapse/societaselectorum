import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from smoke_http import evaluate_page, GAME_CONFIG

def test_good_page_is_runtime_and_asset_green():
    html='<html><script src="https://cdn.websitepublisher.ai/custom/wid27912/js/harun-roguelite.js?v=65"></script></html>'
    r=evaluate_page("harun-roguelite",200,html,[]); assert r["gates"]["RUNTIME_GREEN"]=="GREEN"; assert r["gates"]["ASSET_GREEN"]=="GREEN"
def test_bad_status_is_red(): assert evaluate_page("harun-roguelite",500,"",[])["gates"]["RUNTIME_GREEN"]=="RED"
def test_missing_critical_asset_is_red(): assert evaluate_page("harun-survivor",200,"<html></html>",[])["gates"]["ASSET_GREEN"]=="RED"
def test_failed_critical_request_is_red():
    r=evaluate_page("harun-roguelite",200,'<script src="js/harun-roguelite.js"></script>',["harun-roguelite.js"]); assert r["gates"]["ASSET_GREEN"]=="RED"
def test_archive_routes_are_not_active_games():
    active={v["route"] for v in GAME_CONFIG.values()}; assert "/mundus-fps.html" not in active; assert "/survivor-lab.html" not in active
