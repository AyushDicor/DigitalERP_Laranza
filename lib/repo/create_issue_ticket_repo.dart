import 'dart:developer';
import 'package:digitalerp/model/response_model.dart';
import 'package:digitalerp/repo/base_api_helper.dart';
import 'package:digitalerp/repo/base_url.dart';

class CreateIssueTicketRepo {
  static Future<ResponseItem> organizationNameListMethod(Map<String, dynamic> requestData) async {
    try {
      String requestUrl = AppUrls.baseUrl + MethodName.organizationFetchApi;

      ResponseItem result = await BaseApiHelper.postRequest(requestUrl, requestData);

      return result;
    } catch (e) {
      return ResponseItem(
        status: false,
        message: "organizationNameListMethod Repo : An error occurred: ${e.toString()}",
      );
    }
  }

  static Future<ResponseItem> updateTicketEntryMethod(Map<String, dynamic> requestData) async {
    try {
      String requestUrl = AppUrls.baseUrl + MethodName.updateTicketEntry;

      ResponseItem result = await BaseApiHelper.postRequest(requestUrl, requestData);

      return result;
    } catch (e) {
      return ResponseItem(
        status: false,
        message: "updateTicketEntryMethod Repo : An error occurred: ${e.toString()}",
      );
    }
  }

  static Future<ResponseItem> userNameListMethod(Map<String, dynamic> requestData) async {
    try {
      String requestUrl = AppUrls.baseUrl + MethodName.userNameFetchApi;

      ResponseItem result = await BaseApiHelper.postRequest(requestUrl, requestData);

      return result;
    } catch (e) {
      return ResponseItem(
        status: false,
        message: "userNameListMethod Repo : An error occurred: ${e.toString()}",
      );
    }
  }

  static Future<ResponseItem> issueTypeListMethod(Map<String, dynamic> requestData) async {
    try {
      String requestUrl = AppUrls.baseUrl + MethodName.issueTypeFetchApi;

      ResponseItem result = await BaseApiHelper.postRequest(requestUrl, requestData);

      return result;
    } catch (e) {
      return ResponseItem(
        status: false,
        message: "issueTypeListMethod Repo : An error occurred: ${e.toString()}",
      );
    }
  }

  static Future<ResponseItem> moduleDropdownListMethod(Map<String, dynamic> requestData) async {
    try {
      String requestUrl = AppUrls.baseUrl + MethodName.moduleDropdown;

      ResponseItem result = await BaseApiHelper.postRequest(requestUrl, requestData);

      return result;
    } catch (e) {
      return ResponseItem(
          status: false, message: "moduleDropdownListMethod Repo : An error occurred: ${e.toString()}");
    }
  }

  static Future<ResponseItem> relatedServicesListMethod(Map<String, dynamic> requestData) async {
    try {
      String requestUrl = AppUrls.baseUrl + MethodName.relatedServices;
      log('requestUrl for related Servies=================>>>>>${requestUrl}');

      ResponseItem result = await BaseApiHelper.postRequest(requestUrl, requestData);

      return result;
    } catch (e) {
      return ResponseItem(
        status: false,
        message: "relatedServicesListMethod Repo : An error occurred: ${e.toString()}",
      );
    }
  }

  static Future<ResponseItem> submitIssueTicketMethod(Map<String, dynamic> requestData) async {
    try {
      String requestUrl = AppUrls.baseUrl + MethodName.ticketList;

      ResponseItem result = await BaseApiHelper.postRequest(requestUrl, requestData);

      return result;
    } catch (e) {
      return ResponseItem(
        status: false,
        message: "submitIssueTicketMethod Repo : An error occurred: ${e.toString()}",
      );
    }
  }

  static Future<ResponseItem> getAllTicKetList(Map<String, dynamic> requestData) async {
    try {
      String requestUrl = AppUrls.baseUrl + MethodName.getAllTicketList;
      log('requestUrlgetAllTicKetList=================>>>>>${requestUrl}');

      ResponseItem result = await BaseApiHelper.postRequest(requestUrl, requestData);

      return result;
    } catch (e) {
      return ResponseItem(
        status: false,
        message: "getAllTicKetList Repo : An error occurred: ${e.toString()}",
      );
    }
  }
}
