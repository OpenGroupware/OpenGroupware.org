#!/usr/bin/python

import xmlrpclib, time, sys, os;
import XmlRpcdClient;

# write team ({login:'l', globalId:'url', version:'1',
# emails:('email1', ..)}, ...)
# if version == -1 this team is marked as dead, it will be removed

class WriteTeams(XmlRpcdClient.XmlRpcdClient):

    def write(self):
        dict  = {};
        teams = self.server().team.fetchAllMTAInfo();

        for a in teams:
            l = str(a['login']);

            for e in a['emails']:
                if dict.has_key(e):
                    emails = dict[e];
                else:
                    emails = [];

                emails.append(l);
                dict[e] = emails;

        self.writePostmap(self.dataFilePath(), dict);

    # fetch and write only a

    def dataFile(self):
        return os.getenv('team_file');

# class: WriteTeams
