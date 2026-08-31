#!/usr/bin/env python3
"""统计 Sepolia 上指定发送方给候选账户的近期原生 ETH 转账。"""

import argparse
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from urllib.parse import urlencode
from urllib.request import Request, urlopen


API_URL = "https://api.etherscan.io/v2/api"
CHAIN_ID = "11155111"
PAGE_SIZE = 1000
ADDRESS_RE = re.compile(r"^0x[0-9a-fA-F]{40}$")


def fetch_page(api_key, address, page):
    query = urlencode(
        {
            "chainid": CHAIN_ID,
            "module": "account",
            "action": "txlist",
            "address": address,
            "page": page,
            "offset": PAGE_SIZE,
            "sort": "desc",
            "apikey": api_key,
        }
    )
    request = Request(f"{API_URL}?{query}", headers={"User-Agent": "sepolia-eth-incoming/1"})
    with urlopen(request, timeout=20) as response:
        data = json.load(response)

    if data.get("status") == "1":
        return data["result"]
    if data.get("message") == "No transactions found":
        return []
    raise RuntimeError(f"Etherscan API 错误: {data.get('result', data)}")


def recent_transactions(api_key, address, cutoff):
    transactions = []
    page = 1
    while True:
        batch = fetch_page(api_key, address, page)
        if not batch:
            break
        transactions.extend(tx for tx in batch if int(tx["timeStamp"]) >= cutoff)
        if len(batch) < PAGE_SIZE or int(batch[-1]["timeStamp"]) < cutoff:
            break
        page += 1
        time.sleep(0.25)
    return transactions


def summarize(transactions, sender, recipient):
    matched = [
        tx
        for tx in transactions
        if tx["from"].lower() == sender.lower()
        and tx["to"].lower() == recipient.lower()
        and tx.get("isError") == "0"
        and tx.get("txreceipt_status", "1") == "1"
        and int(tx["value"]) > 0
    ]
    return sum(int(tx["value"]) for tx in matched), max(
        (int(tx["timeStamp"]) for tx in matched), default=None
    ), len(matched)


def wei_to_eth(wei):
    whole, fraction = divmod(wei, 10**18)
    return str(whole) if not fraction else f"{whole}.{fraction:018d}".rstrip("0")


def valid_address(value):
    if not ADDRESS_RE.fullmatch(value):
        raise argparse.ArgumentTypeError(f"无效 Ethereum 地址: {value}")
    return value


def self_test():
    sender = "0x" + "11" * 20
    recipient = "0x" + "22" * 20
    transactions = [
        {"from": sender, "to": recipient, "value": "1200000000000000000", "timeStamp": "20", "isError": "0", "txreceipt_status": "1"},
        {"from": sender, "to": recipient, "value": "300000000000000000", "timeStamp": "30", "isError": "0", "txreceipt_status": "1"},
        {"from": sender, "to": recipient, "value": "9000000000000000000", "timeStamp": "40", "isError": "1", "txreceipt_status": "0"},
    ]
    assert summarize(transactions, sender, recipient) == (1500000000000000000, 30, 2)
    assert wei_to_eth(1500000000000000000) == "1.5"
    print("self-test: OK")


def main():
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        return

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sender", required=True, type=valid_address, help="指定发送账户")
    parser.add_argument("--hours", type=int, default=48, help="统计窗口，默认 48 小时")
    parser.add_argument("recipients", nargs="+", type=valid_address, help="一个或多个候选接收账户")
    args = parser.parse_args()

    if args.hours <= 0:
        parser.error("--hours 必须大于 0")
    api_key = os.environ.get("ETHERSCAN_API_KEY")
    if not api_key:
        parser.error("请先设置环境变量 ETHERSCAN_API_KEY")

    cutoff = int(time.time()) - args.hours * 3600
    print(f"Sepolia | 发送方 {args.sender} | 最近 {args.hours} 小时")
    for recipient in args.recipients:
        total, latest, count = summarize(
            recent_transactions(api_key, recipient, cutoff), args.sender, recipient
        )
        latest_text = (
            datetime.fromtimestamp(latest, timezone.utc).isoformat(timespec="seconds")
            if latest
            else "无"
        )
        print(
            f"{recipient}  笔数={count}  总额={wei_to_eth(total)} ETH"
            f"  ({total} Wei)  最后转账={latest_text}"
        )


if __name__ == "__main__":
    main()
