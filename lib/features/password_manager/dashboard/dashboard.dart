import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverAppBar(
                centerTitle: true,
                toolbarHeight: 100,

                flexibleSpace: FlexibleSpaceBar(
                  background: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverAppBar(
                pinned: true,
                centerTitle: true,
                floating: true,
                expandedHeight: 200,
                title: Text(
                  'Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(child: Text('Welcome to the Dashboard!')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
