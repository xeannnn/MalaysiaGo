import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../models.dart';


class HeritageDetailScreen extends StatefulWidget {

  final HeritageSite site;

  const HeritageDetailScreen({
    super.key,
    required this.site,
  });


  @override
  State<HeritageDetailScreen> createState() =>
      _HeritageDetailScreenState();

}



class _HeritageDetailScreenState
    extends State<HeritageDetailScreen> {


  int selectedTab = 0;



  @override
  Widget build(BuildContext context) {


    final site = widget.site;


    return Scaffold(

      backgroundColor: Colors.white,


      body: SafeArea(

        child: Column(

          children: [


            _buildHeader(site),


            _buildTabs(),


            Expanded(

              child: SingleChildScrollView(

                padding:
                const EdgeInsets.all(20),

                child:
                _buildContent(site),

              ),

            ),


            _buildPassportButton(),


          ],

        ),

      ),

    );

  }





  Widget _buildHeader(HeritageSite site) {


    return Container(

      height: 230,


      padding:
      const EdgeInsets.fromLTRB(
          20,
          15,
          20,
          20
      ),


      decoration: BoxDecoration(


        image: site.imageUrl.isNotEmpty

            ? DecorationImage(

          image:
          NetworkImage(site.imageUrl),

          fit:
          BoxFit.cover,

          colorFilter:
          ColorFilter.mode(

            Colors.black.withOpacity(0.35),

            BlendMode.darken,

          ),

        )

            : null,


        gradient:
        site.imageUrl.isEmpty

            ? const LinearGradient(

          colors: [

            Color(0xffB7D8C8),

            Color(0xff557568),

          ],

          begin:
          Alignment.topCenter,

          end:
          Alignment.bottomCenter,

        )

            : null,

      ),




      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,


        children: [


          Row(

            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,


            children: [


              CircleAvatar(

                backgroundColor:
                Colors.black26,


                child:
                IconButton(

                  icon:
                  const Icon(

                    Icons.arrow_back,

                    color:
                    Colors.white,

                  ),

                  onPressed: (){

                    Navigator.pop(context);

                  },

                ),

              ),



              Container(

                padding:
                const EdgeInsets.symmetric(

                    horizontal:10,

                    vertical:5

                ),


                decoration:
                BoxDecoration(

                  color:
                  Colors.green,

                  borderRadius:
                  BorderRadius.circular(20),

                ),


                child:
                const Text(

                  "✓ Visited",

                  style:
                  TextStyle(

                    color:
                    Colors.white,

                    fontWeight:
                    FontWeight.bold,

                  ),

                ),

              ),

            ],

          ),



          const Spacer(),



          Row(

            children: [


              _tag(site.category),


              const SizedBox(width:8),


              _tag(
                  "• ${site.difficulty}"
              ),


              const Spacer(),



              Container(

                padding:
                const EdgeInsets.all(10),


                decoration:
                BoxDecoration(

                  color:
                  Colors.orange,

                  borderRadius:
                  BorderRadius.circular(15),

                ),


                child:
                Text(

                  "+${site.xp} XP",

                  style:
                  const TextStyle(

                    color:
                    Colors.white,

                    fontWeight:
                    FontWeight.bold,

                  ),

                ),

              )


            ],

          ),




          const SizedBox(height:8),



          Text(

            site.name,


            style:
            const TextStyle(

              color:
              Colors.white,

              fontSize:
              24,

              fontWeight:
              FontWeight.bold,

            ),

          ),



          Text(

            site.location,


            style:
            const TextStyle(

              color:
              Colors.white70,

              fontSize:
              14,

            ),

          ),


        ],

      ),

    );

  }






  Widget _tag(String text){


    return Container(

      padding:
      const EdgeInsets.symmetric(

          horizontal:10,

          vertical:5

      ),


      decoration:
      BoxDecoration(

        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(20),

      ),


      child:
      Text(

        text,

        style:
        const TextStyle(

          color:
          Colors.green,

          fontSize:
          12,

          fontWeight:
          FontWeight.bold,

        ),

      ),

    );

  }







  Widget _buildTabs(){


    final tabs = [

      "📖 Overview",

      "💡 Tips",

      "ℹ️ Visit Info",

    ];



    return Row(

      children:

      List.generate(

        tabs.length,

            (index){


          return Expanded(


            child:
            GestureDetector(


              onTap: (){


                setState(() {

                  selectedTab=index;

                });


              },


              child:
              Container(

                padding:
                const EdgeInsets.all(15),


                decoration:
                BoxDecoration(

                  border:
                  Border(

                    bottom:
                    BorderSide(

                      color:

                      selectedTab == index

                          ?

                      Colors.green

                          :

                      Colors.transparent,


                      width:
                      2,

                    ),

                  ),

                ),



                child:
                Text(

                  tabs[index],


                  textAlign:
                  TextAlign.center,


                  style:
                  TextStyle(

                    fontSize:
                    12,


                    color:

                    selectedTab == index

                        ?

                    Colors.green

                        :

                    Colors.grey,

                    fontWeight:
                    FontWeight.bold,

                  ),

                ),

              ),

            ),

          );


        },

      ),

    );


  }







  Widget _buildContent(HeritageSite site){


    if(selectedTab == 1){

      return _tips(site);

    }


    if(selectedTab == 2){

      return _visitInfo(site);

    }


    return _overview(site);


  }







  Widget _overview(HeritageSite site){


    return Column(

      crossAxisAlignment:
      CrossAxisAlignment.start,


      children: [



        Container(

          padding:
          const EdgeInsets.all(15),


          decoration:
          BoxDecoration(

            color:
            const Color(0xffE8FFF3),

            borderRadius:
            BorderRadius.circular(15),

          ),


          child:
          Text(

            site.description,

            style:
            const TextStyle(

              color:
              Colors.green,

              fontWeight:
              FontWeight.bold,

            ),

          ),

        ),



        const SizedBox(height:20),



        Text(

          site.description,

          style:
          const TextStyle(

            fontSize:
            15,

            height:
            1.5,

          ),

        ),




        const SizedBox(height:20),



        Row(

          children: [


            Expanded(

              child:
              _smallCard(

                "Best Time",

                site.bestTime,

              ),

            ),



            const SizedBox(width:10),



            Expanded(

              child:
              _smallCard(

                "Duration",

                site.duration,

              ),

            ),

          ],

        ),



        const SizedBox(height:20),



        _map(site),



      ],

    );

  }







  Widget _smallCard(String title,String value){


    return Container(

      padding:
      const EdgeInsets.all(12),


      decoration:
      BoxDecoration(

        color:
        Colors.grey.shade100,

        borderRadius:
        BorderRadius.circular(15),

      ),


      child:
      Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,


        children: [


          Text(

            title,

            style:
            const TextStyle(

              color:
              Colors.grey,

              fontSize:
              12,

            ),

          ),



          const SizedBox(height:5),



          Text(

            value,

            style:
            const TextStyle(

              fontWeight:
              FontWeight.bold,

            ),

          )


        ],

      ),

    );

  }







  Widget _tips(HeritageSite site){


    return Column(

      children:


      site.tips.map(

              (tip)=>Card(

            child:
            ListTile(

              leading:
              const CircleAvatar(

                backgroundColor:
                Colors.green,

                child:
                Icon(

                  Icons.check,

                  color:
                  Colors.white,

                ),

              ),

              title:
              Text(tip),

            ),

          )

      ).toList(),


    );


  }







  Widget _visitInfo(HeritageSite site){


    return Column(

      children: [


        _info(
            "Opening Hours",
            site.openingHours
        ),


        _info(
            "Entry Fee",
            site.entryFee
        ),


        _info(
            "Category",
            site.category
        ),


        _info(
            "Difficulty",
            site.difficulty
        ),


        _info(
            "XP Reward",
            "+${site.xp} XP"
        ),


      ],

    );

  }







  Widget _info(String title,String value){


    return Card(

      child:
      ListTile(

        title:
        Text(

          title,

          style:
          const TextStyle(

              color:
              Colors.grey

          ),

        ),


        subtitle:
        Text(

          value,

          style:
          const TextStyle(

            fontWeight:
            FontWeight.bold,

          ),

        ),

      ),

    );

  }







  Widget _map(HeritageSite site) {

    return SizedBox(

      height: 200,


      child: ClipRRect(

        borderRadius:
        BorderRadius.circular(20),


        child: FlutterMap(

          options: MapOptions(

            initialCenter: ll.LatLng(

              site.latitude,

              site.longitude,

            ),


            // reduced from 15 to 14
            // prevents Batu Caves tile loading issue
            initialZoom: 14,


          ),



          children: [


            TileLayer(

              urlTemplate:

              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",


              userAgentPackageName:

              "com.example.malaysiago",


              maxZoom:

              19,


            ),



            MarkerLayer(

              markers: [


                Marker(

                  point:

                  ll.LatLng(

                    site.latitude,

                    site.longitude,

                  ),


                  width:

                  50,


                  height:

                  50,


                  child:

                  const Icon(

                    Icons.location_pin,

                    color:

                    Colors.red,

                    size:

                    45,

                  ),

                ),


              ],

            ),



            const RichAttributionWidget(

              attributions: [

                TextSourceAttribution(

                  '© OpenStreetMap contributors',

                ),

              ],

            ),


          ],


        ),

      ),

    );

  }







  Widget _buildPassportButton(){


    return Container(

      padding:
      const EdgeInsets.all(15),


      width:
      double.infinity,


      child:
      ElevatedButton(

        style:
        ElevatedButton.styleFrom(

          backgroundColor:
          Colors.deepPurple,

          padding:
          const EdgeInsets.all(15),

          shape:
          RoundedRectangleBorder(

            borderRadius:
            BorderRadius.circular(15),

          ),

        ),


        onPressed: (){},


        child:
        const Text(

          "🧩 View in Passport",

          style:
          TextStyle(

            color:
            Colors.white,

            fontWeight:
            FontWeight.bold,

          ),

        ),

      ),

    );


  }


}