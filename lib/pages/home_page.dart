import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dapp/constant.dart';
import 'package:flutter_dapp/slider/Slider_widget.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.text}) : super(key: key);
  final String text;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Client httpClient;
  Web3Client ethClient;
  bool data = false;
  int myAmount = 0;
  final myAdress = "0xc71f88dAcD01441CF137fD68cD33bAC2Fb1Ab7c4";
  String txHash;
  var myData;

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client(
      "https://rinkeby.infura.io/v3/a8fada504ef84857aed08c1df5664656",
      httpClient,
    );
    getBalance(myAdress);
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0xc7efA677522B06Fe684Bd790320BEa2014F5d636";

    final contract = DeployedContract(ContractAbi.fromJson(abi, "PKCoin"),
        EthereumAddress.fromHex(contractAddress));

    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
        contract: contract, function: ethFunction, params: args);

    return result;
  }

  Future<void> getBalance(String targetAddress) async {
    //EthereumAddress address = EthereumAddress.fromHex(targetAddress);
    List<dynamic> result = await query("getBalance", []);

    myData = result[0];
    data = true;
    setState(() {});
  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    EthPrivateKey credentials = EthPrivateKey.fromHex(
        "8ad47949e25f5478fc873c737e6b7653aa96d4ddcc072f1ff0df202743ec8d3b");

    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(
        credentials,
        Transaction.callContract(
            contract: contract, function: ethFunction, parameters: args),
        fetchChainIdFromNetworkId: true);
    return result;
  }

  Future<String> sendCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("depositBalance", [bigAmount]);

    print("Deposited");
    txHash = response;
    setState(() {});
    return response;
  }

  Future<String> withdrawCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("withdrawBalance", [bigAmount]);

    print("Withdraw");
    txHash = response;
    setState(() {});
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coins'),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey[300],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(8),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Balance',
                    style: TextStyle(fontSize: 25),
                  ),
                  SizedBox(height: 10),
                  data
                      ? Text(
                          '\$$myData',
                          style: TextStyle(
                              fontSize: 35, fontWeight: FontWeight.bold),
                        )
                      : CircularProgressIndicator(),
                ],
              ),
            ),
            SizedBox(height: 20),
            SliderWidget(
              min: 0,
              max: 100,
              finalVal: (value) {
                myAmount = (value * 100).round();
                print(myAmount);
              },
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => getBalance(myAdress),
                  style: TextButton.styleFrom(
                    backgroundColor: kRefreshColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.refresh,
                        color: kIconsColor,
                      ),
                      Text('Refresh',
                          style: TextStyle(color: kTextColor, fontSize: 20)),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                TextButton(
                  onPressed: () => sendCoin(),
                  style: TextButton.styleFrom(
                    backgroundColor: kDepositColor,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.call_made_outlined,
                        color: kIconsColor,
                      ),
                      Text('Deposit',
                          style: TextStyle(color: kTextColor, fontSize: 20)),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                TextButton(
                  onPressed: () => withdrawCoin(),
                  style: TextButton.styleFrom(
                    backgroundColor: kWithdrawColor,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.call_received_outlined, color: kIconsColor),
                      Text(
                        'Withdraw',
                        style: TextStyle(color: kTextColor, fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            if (txHash != null) Text('$txHash'),
          ],
        ),
      ),
    );
  }
}
