"""Ask a saved v7 model without NumPy, SciPy, training data, or a network."""
import argparse
import json
from pathlib import Path
from model import Session, TokenGraph


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("question", nargs="+")
    parser.add_argument("--model", type=Path, default=Path(__file__).parent / "results/neurograph_contextual_v7.ngs")
    parser.add_argument("--session", type=Path, help="Optional persistent context file")
    parser.add_argument("--trace", action="store_true")
    args = parser.parse_args()
    model = TokenGraph.load(args.model)
    session = Session.load(args.session, model) if args.session and args.session.exists() else Session()
    result = model.respond(" ".join(args.question), session)
    if args.session:
        session.save(args.session, model)
    if args.trace:
        print(json.dumps(vars(result), ensure_ascii=False, indent=2))
    else:
        print(result.text)


if __name__ == "__main__":
    main()
